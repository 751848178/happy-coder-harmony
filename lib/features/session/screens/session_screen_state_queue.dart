part of 'session_screen.dart';

extension _SessionScreenStateQueue on _SessionScreenState {
  Future<void> _reconcileQueuedMessageState() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final messages =
        sessionNotifier.getSessionMessages(widget.sessionId)?.messages ??
            const <ReducerMessage>[];
    final turnGroups = _MessageTurnGroup.build(messages);

    final activeLocalId = _activeResponseLocalId;
    if (activeLocalId != null) {
      final activeGroup = _findTurnGroupByLocalId(turnGroups, activeLocalId) ??
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
