part of 'session_screen.dart';

extension _SessionScreenStateLoad on _SessionScreenState {
  void _refreshSessionContextInBackground(
    SessionServiceNotifier sessionNotifier,
  ) {
    // Schedule background refresh after a short delay to avoid racing with
    // the in-flight message load.  loadSessions() clears _sessionDataKeys,
    // and if it runs while loadSessionMessages is still decrypting, messages
    // silently fail to decrypt → empty list with isLoaded: true.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      unawaited(sessionNotifier.loadSessions().catchError((Object error) {
        Logger.warning('Failed to refresh sessions in background: $error');
      }));
      unawaited(
        sessionNotifier
            .loadMachines(force: false, allowFailure: true)
            .catchError((Object error) {
          Logger.warning('Failed to refresh machines in background: $error');
        }),
      );
    });
  }

  Future<void> _ensureSessionContextLoaded(
    SessionServiceNotifier sessionNotifier, {
    required bool requireSession,
    bool forceLoadSessions = true,
  }) async {
    final tasks = <Future<void>>[];
    if (requireSession) {
      tasks.add(sessionNotifier.loadSessions(force: forceLoadSessions));
    }
    if (sessionNotifier.machines.isEmpty) {
      tasks.add(
        sessionNotifier.loadMachines(force: true, allowFailure: true),
      );
    }
    if (tasks.isEmpty) {
      return;
    }
    await Future.wait(tasks);
  }

  Future<void> _loadNonCriticalUiData() async {
    final results = await Future.wait([
      _inputTemplateService.loadTemplates(),
      _uiStateService.get(widget.sessionId),
    ]);
    if (!mounted) {
      return;
    }
    final templates = results[0] as List<SessionInputTemplate>;
    final uiState = results[1] as SessionUiState;
    _updateState(() {
      _customInputTemplates =
          List<SessionInputTemplate>.unmodifiable(templates);
      _sessionOverviewCollapsed = uiState.overviewCollapsed;
      _collapseAllTurns = uiState.collapseAllTurns;
      _expandedTurnIds
        ..clear()
        ..addAll(uiState.expandedTurnIds);
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
    _queuedMessagesN.value = queuedMessages;
  }

  Future<void> _storeQueuedComposerMessages(
    List<QueuedComposerMessage> queuedMessages,
  ) async {
    if (mounted) {
      _queuedMessagesN.value = List<QueuedComposerMessage>.from(queuedMessages);
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
    final initialSession = sessionNotifier.getSession(widget.sessionId);
    final initialMessages =
        sessionNotifier.getSessionMessages(widget.sessionId);
    final hasCachedMessageSnapshot = initialMessages?.isLoaded == true;
    final requiresBlockingLoad =
        initialSession == null || !hasCachedMessageSnapshot;

    _restoreComposerDraft(initialSession, force: true);
    if (requiresBlockingLoad) {
      _setSessionRefreshing(true);
    }
    try {
      // Always ensure sessions are loaded so that _sessionDataKeys is
      // populated — without data keys, loadSessionMessages cannot decrypt
      // messages and silently produces an empty list with isLoaded: true,
      // causing the UI to show an empty-state placeholder instead of the
      // actual conversation.
      await _ensureSessionContextLoaded(
        sessionNotifier,
        requireSession: true,
        forceLoadSessions: initialSession == null,
      );
      final loadedSession = sessionNotifier.getSession(widget.sessionId);
      _restoreComposerDraft(loadedSession, force: true);
      if (loadedSession == null) {
        return;
      }
      if (hasCachedMessageSnapshot) {
        unawaited(
          sessionNotifier.loadSessionMessages(widget.sessionId).catchError((
            Object error,
          ) {
            Logger.warning(
              'Failed to refresh cached session messages for '
              '${widget.sessionId}: $error',
            );
          }),
        );
      } else {
        await sessionNotifier.loadSessionMessages(
          widget.sessionId,
          force: true,
        );
      }
      _restoreComposerDraft(
        sessionNotifier.getSession(widget.sessionId),
        force: true,
      );
      await _maybeAutoApprovePendingTools();
      _scheduleScrollToLatest(force: true);
      _refreshSessionContextInBackground(sessionNotifier);

      // 订阅 Socket 消息
      ref
          .read(socketStateProvider.notifier)
          .subscribeToSession(widget.sessionId);
      _startMessagePolling();
    } finally {
      if (requiresBlockingLoad) {
        _setSessionRefreshing(false);
      }
      _initialLoadComplete = true;
    }
  }
}
