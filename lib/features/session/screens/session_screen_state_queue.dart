part of 'session_screen.dart';

extension _SessionScreenStateQueue on _SessionScreenState {
  bool _remoteAbortHasSettled(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    if (!_awaitingAbortRemoteSettle) {
      return false;
    }
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    return sessionAbortHasSettledRemotely(
      session: session,
      messages: latestGroup?.messages ?? const <ReducerMessage>[],
      userPrompt: latestGroup?.userPrompt,
      isSending: _isSending,
    );
  }

  bool _hasEffectiveActiveResponseMarker(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    SessionThinkingSnapshot? thinkingSnapshot,
  }) {
    final activeLocalId = _activeResponseLocalId;
    if (activeLocalId == null) {
      return false;
    }
    return !_remoteAbortHasSettled(session, turnGroups);
  }

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
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    final remoteAbortSettled = _remoteAbortHasSettled(session, turnGroups);

    if (remoteAbortSettled && mounted) {
      _updateState(() {
        _awaitingAbortRemoteSettle = false;
        _manualThinkingOverride = null;
        _activeResponseLocalId = null;
      });
    }

    if (_manualThinkingOverride != null &&
        sessionTurnHasCompletionSignal(
          latestGroup?.messages ?? const <ReducerMessage>[],
        )) {
      if (mounted) {
        _updateState(() {
          _manualThinkingOverride = null;
        });
      }
    }

    final activeLocalId = _activeResponseLocalId;
    if (activeLocalId != null) {
      // 修复会话中断后 activeResponseLocalId 无法清除的问题：
      // 如果会话思考时间超过阈值，直接清除 activeResponseLocalId
      if (_isResponseLocalIdTimedOut(session, activeLocalId)) {
        if (mounted) {
          _updateState(() {
            _activeResponseLocalId = null;
            _awaitingAbortRemoteSettle = false;
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
              _awaitingAbortRemoteSettle = false;
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
    List<_MessageTurnGroup> turnGroups, {
    SessionThinkingSnapshot? thinkingSnapshot,
  }) {
    if (_isSending || _isAutoSendingQueuedMessage) {
      return true;
    }
    if (_manualThinkingOverride == false) {
      return false;
    }
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    final activeLocalId =
        _hasEffectiveActiveResponseMarker(session, turnGroups)
            ? _activeResponseLocalId
            : null;
    if (activeLocalId != null) {
      return true;
    }
    // Use cached snapshot when available to avoid redundant message list copies.
    final isThinking = thinkingSnapshot != null
        ? thinkingSnapshot.isThinking
        : sessionTurnIsThinkingStillBlocking(
            session: session,
            messages: latestGroup?.messages ?? const <ReducerMessage>[],
            manualThinkingOverride: _manualThinkingOverride,
          );
    if (isThinking) {
      return true;
    }
    if (sessionTurnHasBlockingToolWork(
        latestGroup?.messages ?? const <ReducerMessage>[])) {
      return true;
    }
    if (latestGroup?.userPrompt?.metadata?['optimistic'] == true) {
      return true;
    }
    return false;
  }
}
