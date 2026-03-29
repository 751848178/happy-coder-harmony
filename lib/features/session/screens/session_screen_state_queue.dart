part of 'session_screen.dart';

extension _SessionScreenStateQueue on _SessionScreenState {
  void _scheduleQueuedMessageReconciliation(
    Session? session,
    List<ReducerMessage> messages,
  ) {
    final shouldSchedule = !identical(_queuedReconcileSession, session) ||
        !identical(_queuedReconcileMessages, messages) ||
        _queuedReconcileQueueSize != _queuedMessages.length ||
        _queuedReconcileActiveResponseLocalId != _activeResponseLocalId ||
        _queuedReconcileIsSending != _isSending ||
        _queuedReconcileIsAutoSending != _isAutoSendingQueuedMessage ||
        _queuedReconcileManualThinkingOverride != _manualThinkingOverride;
    if (!shouldSchedule || _queueReconcileScheduled) {
      return;
    }

    _queuedReconcileSession = session;
    _queuedReconcileMessages = messages;
    _queuedReconcileQueueSize = _queuedMessages.length;
    _queuedReconcileActiveResponseLocalId = _activeResponseLocalId;
    _queuedReconcileIsSending = _isSending;
    _queuedReconcileIsAutoSending = _isAutoSendingQueuedMessage;
    _queuedReconcileManualThinkingOverride = _manualThinkingOverride;
    _queueReconcileScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueReconcileScheduled = false;
      if (!mounted) {
        return;
      }
      unawaited(_reconcileQueuedMessageState());
    });
  }

  /// 检查 activeResponseLocalId 是否超时
  /// 如果会话思考时间超过阈值，认为可能已中断，应清除 activeResponseLocalId
  bool _isResponseLocalIdTimedOut(Session? session, String? activeLocalId) {
    if (activeLocalId == null || session == null) {
      return false;
    }
    // 如果会话思考时间超过 2 分钟，认为可能已中断
    final thinking = session.thinking;
    final thinkingAt = session.thinkingAt;
    if (thinking != true || thinkingAt == null) {
      return false;
    }
    final timeoutDuration = const Duration(minutes: 2);
    final elapsed = DateTime.now().difference(thinkingAt);
    return elapsed >= timeoutDuration;
  }

  Future<void> _reconcileQueuedMessageState() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final messages =
        sessionNotifier.getSessionMessages(widget.sessionId)?.messages ??
            const <ReducerMessage>[];
    final turnGroups = _resolveTurnGroups(messages);

    final activeLocalId = _activeResponseLocalId;
    if (activeLocalId != null) {
      // 修复会话中断后 activeResponseLocalId 无法清除的问题：
      // 如果会话思考时间超过阈值，直接清除 activeResponseLocalId
      if (_isResponseLocalIdTimedOut(session, activeLocalId)) {
        if (mounted) {
          _updateState(() {
            _activeResponseLocalId = null;
          });
        }
      } else {
        final activeGroup =
            _findTurnGroupByLocalId(turnGroups, activeLocalId) ??
                (turnGroups.isNotEmpty ? turnGroups.last : null);
        if (sessionActiveResponseHasCompleted(
          session: session,
          messages: activeGroup?.messages ?? const <ReducerMessage>[],
          userPrompt: activeGroup?.userPrompt,
          isSending: _isSending,
        )) {
          if (mounted) {
            _updateState(() {
              _activeResponseLocalId = null;
            });
          }
        }
      }
    }

    await _maybeSendNextQueuedMessage(session, turnGroups);
  }

  _MessageTurnGroup? _findTurnGroupByLocalId(
    List<_MessageTurnGroup> turnGroups,
    String localId,
  ) {
    for (final group in turnGroups) {
      final promptLocalId = group.userPrompt?.metadata?['localId']?.toString();
      if (promptLocalId == localId) {
        return group;
      }
    }
    return null;
  }

  bool _isConversationBusy(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    return sessionConversationIsBusy(
      session: session,
      latestTurnMessages: latestGroup?.messages ?? const <ReducerMessage>[],
      latestUserPrompt: latestGroup?.userPrompt,
      isSending: _isSending,
      isAutoSendingQueuedMessage: _isAutoSendingQueuedMessage,
      activeResponseLocalId: _activeResponseLocalId,
      manualThinkingOverride: _manualThinkingOverride,
    );
  }

  Future<void> _maybeSendNextQueuedMessage(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    if (session == null) {
      return;
    }
    if (_queuedMessages.isEmpty || _isConversationBusy(session, turnGroups)) {
      return;
    }
    if (_isAutoSendingQueuedMessage) {
      return;
    }

    final nextMessage = _queuedMessages.first;
    final remaining = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(0);

    _updateState(() {
      _isAutoSendingQueuedMessage = true;
      _queuedMessages = remaining;
    });

    try {
      try {
        await _composerQueueService.replace(widget.sessionId, remaining);
      } catch (error) {
        if (mounted) {
          final restoredQueue = <QueuedComposerMessage>[
            nextMessage,
            ..._queuedMessages,
          ];
          _updateState(() {
            _queuedMessages = restoredQueue;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('更新待发送消息失败: $error'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      final sent = await _dispatchMessage(
        nextMessage.content,
        restoreComposerOnError: false,
      );
      if (!sent && mounted) {
        final restoredQueue = <QueuedComposerMessage>[
          nextMessage,
          ..._queuedMessages,
        ];
        _updateState(() {
          _queuedMessages = restoredQueue;
        });
        await _composerQueueService.replace(widget.sessionId, restoredQueue);
      }
    } finally {
      if (mounted) {
        _updateState(() {
          _isAutoSendingQueuedMessage = false;
        });
      }
    }
  }

  Future<void> _enqueueComposerMessage(String content, {int? insertAt}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final nextMessage = _composerQueueService.createDraft(trimmed);
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages);
    final targetIndex = insertAt == null
        ? nextQueue.length
        : insertAt.clamp(0, nextQueue.length);
    nextQueue.insert(targetIndex, nextMessage);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _removeQueuedComposerMessage(String messageId) async {
    final nextQueue = _queuedMessages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    await _storeQueuedComposerMessages(nextQueue);
  }

  Future<void> _editQueuedComposerMessage(QueuedComposerMessage message) async {
    final index = _queuedMessages.indexWhere((item) => item.id == message.id);
    if (index < 0) {
      return;
    }
    final currentDraft = _messageController.text.trim();
    final nextQueue = List<QueuedComposerMessage>.from(_queuedMessages)
      ..removeAt(index);
    if (currentDraft.isNotEmpty && currentDraft != message.content.trim()) {
      final preservedDraft = _composerQueueService.createDraft(currentDraft);
      nextQueue.insert(index, preservedDraft);
    }
    await _storeQueuedComposerMessages(nextQueue);
    _setComposerText(message.content);
    _messageFocusNode.requestFocus();
  }

  void _setComposerText(String text) {
    _messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
