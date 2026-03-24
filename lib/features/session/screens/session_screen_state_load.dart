part of 'session_screen.dart';

extension _SessionScreenStateLoad on _SessionScreenState {
  Future<void> _loadCustomInputTemplates() async {
    final templates = await _inputTemplateService.loadTemplates();
    if (!mounted) {
      return;
    }
    _updateState(() {
      _customInputTemplates =
          List<SessionInputTemplate>.unmodifiable(templates);
    });
  }

  void _restoreComposerDraft(
    Session? session, {
    bool force = false,
  }) {
    final draft = session?.draft ?? '';
    if (!force && _messageController.text.isNotEmpty) {
      return;
    }
    if (_messageController.text == draft) {
      return;
    }
    _setComposerText(draft);
  }

  Future<void> _loadSessionUiState() async {
    final state = await _uiStateService.get(widget.sessionId);
    if (!mounted) {
      return;
    }
    _updateState(() {
      _sessionOverviewCollapsed = state.overviewCollapsed;
      _collapseAllTurns = state.collapseAllTurns;
      _expandedTurnIds
        ..clear()
        ..addAll(state.expandedTurnIds);
    });
  }

  Future<void> _persistSessionUiState() {
    return _uiStateService.update(
      widget.sessionId,
      overviewCollapsed: _sessionOverviewCollapsed,
      collapseAllTurns: _collapseAllTurns,
      expandedTurnIds: Set<String>.from(_expandedTurnIds),
    );
  }

  Future<void> _loadQueuedComposerMessages() async {
    final queuedMessages = await _composerQueueService.get(widget.sessionId);
    if (!mounted) {
      return;
    }
    _updateState(() {
      _queuedMessages = queuedMessages;
    });
  }

  Future<void> _storeQueuedComposerMessages(
    List<QueuedComposerMessage> queuedMessages,
  ) async {
    if (mounted) {
      _updateState(() {
        _queuedMessages = List<QueuedComposerMessage>.from(queuedMessages);
      });
    }
    try {
      await _composerQueueService.replace(widget.sessionId, queuedMessages);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新待发送消息失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _loadSessionData() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    _restoreComposerDraft(sessionNotifier.getSession(widget.sessionId),
        force: true);
    if (mounted) {
      _updateState(() {
        _isRefreshingSessionState = true;
      });
    }
    try {
      await sessionNotifier.loadSessions(force: true);
      final loadedSession = sessionNotifier.getSession(widget.sessionId);
      _restoreComposerDraft(loadedSession, force: true);
      if (loadedSession == null) {
        return;
      }
      await sessionNotifier.loadSessionMessages(
        widget.sessionId,
        force: true,
      );
      _restoreComposerDraft(
        sessionNotifier.getSession(widget.sessionId),
        force: true,
      );
      await _maybeAutoApprovePendingTools();
      _scheduleScrollToLatest(force: true);

      // 订阅 Socket 消息
      ref
          .read(socketStateProvider.notifier)
          .subscribeToSession(widget.sessionId);
      _startMessagePolling();
    } finally {
      if (mounted) {
        _updateState(() {
          _isRefreshingSessionState = false;
        });
      }
    }
  }
}
