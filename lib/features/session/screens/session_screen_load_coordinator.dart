part of 'session_screen.dart';

class _SessionScreenLoadCoordinator {
  _SessionScreenLoadCoordinator(this._state);

  final _SessionScreenState _state;

  Future<bool> _restoreLatestMessageWindowIfNeeded(
    SessionServiceNotifier sessionNotifier,
  ) async {
    final sessionMessages =
        sessionNotifier.getSessionMessages(_state.widget.sessionId);
    if (sessionMessages == null || sessionMessages.hasNewerMessages != true) {
      return false;
    }
    await _state._refreshArchivedMessageCount();
    if (!_state._hasCompleteArchivedMessageHistory) {
      return false;
    }
    final stopwatch = Stopwatch()..start();
    final restored =
        await sessionNotifier.loadLatestSessionMessageArchiveWindow(
      _state.widget.sessionId,
      residentWindowSize:
          SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
    );
    stopwatch.stop();
    Logger.info(
      '[SessionEntry] latest-window restore session=${_state.widget.sessionId} '
      'restored=$restored cost=${stopwatch.elapsedMilliseconds}ms',
    );
    if (restored && _state.mounted) {
      _state._syncMessagesFromRepository();
    }
    return restored;
  }

  Future<void> waitForEntryTransitionToSettle() async {
    if (!_state.mounted) {
      return;
    }
    final route = ModalRoute.of(_state.context);
    final animation = route?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    final completer = Completer<void>();
    late AnimationStatusListener listener;
    listener = (status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };
    animation.addStatusListener(listener);
    try {
      await completer.future.timeout(
        const Duration(milliseconds: 360),
        onTimeout: () {},
      );
    } finally {
      animation.removeStatusListener(listener);
      stopwatch.stop();
      Logger.info(
        '[SessionEntry] transition-settled session=${_state.widget.sessionId} '
        'cost=${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  void refreshSessionContextInBackground(
    SessionServiceNotifier sessionNotifier,
  ) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_state.mounted) return;
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

  Future<void> ensureSessionContextLoaded(
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

  void scheduleWarmSessionEntryRefresh(
    SessionServiceNotifier sessionNotifier,
  ) {
    unawaited(() async {
      final stopwatch = Stopwatch()..start();
      await waitForEntryTransitionToSettle();
      if (!_state.mounted) {
        return;
      }
      await ensureSessionContextLoaded(
        sessionNotifier,
        requireSession: true,
        forceLoadSessions: false,
      );
      if (!_state.mounted) {
        return;
      }
      final loadedSession = sessionNotifier.getSession(_state.widget.sessionId);
      _state._restoreComposerDraft(loadedSession, force: true);
      if (loadedSession == null) {
        return;
      }
      try {
        final messageLoadWatch = Stopwatch()..start();
        await sessionNotifier.loadSessionMessages(
          _state.widget.sessionId,
          messageWindowSize:
              SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
        );
        messageLoadWatch.stop();
        Logger.info(
          '[SessionEntry] warm-refresh messages session=${_state.widget.sessionId} '
          'cost=${messageLoadWatch.elapsedMilliseconds}ms',
        );
      } catch (error) {
        Logger.warning(
          'Failed to refresh cached session messages for '
          '${_state.widget.sessionId}: $error',
        );
      }
      if (!_state.mounted) {
        return;
      }
      _state._syncMessagesFromRepository();
      await _state._refreshArchivedMessageCount();
      unawaited(_state._ensureArchivedMessageHistoryAccessible());
      await _state._maybeAutoApprovePendingTools();
      _state._scheduleScrollToLatest(force: true);
      refreshSessionContextInBackground(sessionNotifier);
      _state.ref
          .read(socketStateProvider.notifier)
          .subscribeToSession(_state.widget.sessionId);
      _state._startMessagePolling();
      stopwatch.stop();
      Logger.info(
        '[SessionEntry] warm-refresh complete session=${_state.widget.sessionId} '
        'cost=${stopwatch.elapsedMilliseconds}ms '
        'messages=${_state._messages.length}',
      );
    }());
  }

  Future<void> loadSessionData() async {
    final totalWatch = Stopwatch()..start();
    Logger.info('[SessionEntry] load start session=${_state.widget.sessionId}');
    await SchedulerBinding.instance.endOfFrame;

    if (!_state.mounted) return;

    final sessionNotifier = _state.ref.read(sessionStateProvider.notifier);
    final initialSession = sessionNotifier.getSession(_state.widget.sessionId);
    final initialMessages =
        sessionNotifier.getSessionMessages(_state.widget.sessionId);
    var hasCachedMessageSnapshot = initialMessages?.isLoaded == true;

    if (!hasCachedMessageSnapshot) {
      final cacheRestoreWatch = Stopwatch()..start();
      final restored = await sessionNotifier.restoreSessionMessagesFromCache(
        _state.widget.sessionId,
      );
      cacheRestoreWatch.stop();
      if (restored) {
        final restoredMessages =
            sessionNotifier.getSessionMessages(_state.widget.sessionId);
        hasCachedMessageSnapshot = restoredMessages?.isLoaded == true;
      }
      Logger.info(
        '[SessionEntry] cache-restore session=${_state.widget.sessionId} '
        'restored=$restored loaded=$hasCachedMessageSnapshot '
        'cost=${cacheRestoreWatch.elapsedMilliseconds}ms',
      );
    }

    if (hasCachedMessageSnapshot) {
      await _restoreLatestMessageWindowIfNeeded(sessionNotifier);
      _state._syncMessagesFromRepository();
    }

    final requiresBlockingLoad =
        initialSession == null || !hasCachedMessageSnapshot;

    _state._restoreComposerDraft(initialSession, force: true);
    if (initialSession != null && hasCachedMessageSnapshot) {
      unawaited(_state._refreshArchivedMessageCount());
      _state._initialLoadComplete = true;
      scheduleWarmSessionEntryRefresh(sessionNotifier);
      unawaited(_state._ensureArchivedMessageHistoryAccessible());
      return;
    }
    if (requiresBlockingLoad) {
      _state._setSessionRefreshing(true);
    }
    try {
      final contextWatch = Stopwatch()..start();
      await ensureSessionContextLoaded(
        sessionNotifier,
        requireSession: true,
        forceLoadSessions: initialSession == null,
      );
      contextWatch.stop();
      Logger.info(
        '[SessionEntry] context-ready session=${_state.widget.sessionId} '
        'cost=${contextWatch.elapsedMilliseconds}ms',
      );
      final loadedSession = sessionNotifier.getSession(_state.widget.sessionId);
      _state._restoreComposerDraft(loadedSession, force: true);
      if (loadedSession == null) {
        return;
      }
      if (!hasCachedMessageSnapshot) {
        await _state._refreshArchivedMessageCount();
        if (_state._hasCompleteArchivedMessageHistory) {
          final archiveRestoreWatch = Stopwatch()..start();
          final restoredFromArchive =
              await sessionNotifier.loadLatestSessionMessageArchiveWindow(
            _state.widget.sessionId,
            residentWindowSize:
                SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
          );
          archiveRestoreWatch.stop();
          if (restoredFromArchive) {
            hasCachedMessageSnapshot = true;
            Logger.info(
              '[SessionEntry] archive-restore session=${_state.widget.sessionId} '
              'loaded=true cost=${archiveRestoreWatch.elapsedMilliseconds}ms',
            );
            _state._syncMessagesFromRepository();
          }
        }
      } else {
        await _restoreLatestMessageWindowIfNeeded(sessionNotifier);
      }
      if (!hasCachedMessageSnapshot) {
        final messageLoadWatch = Stopwatch()..start();
        await sessionNotifier.loadSessionMessages(
          _state.widget.sessionId,
          force: !hasCachedMessageSnapshot,
          messageWindowSize:
              SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
        );
        messageLoadWatch.stop();
        Logger.info(
          '[SessionEntry] message-load session=${_state.widget.sessionId} '
          'force=${!hasCachedMessageSnapshot} '
          'cost=${messageLoadWatch.elapsedMilliseconds}ms',
        );
      }
      _state._syncMessagesFromRepository();
      await _state._refreshArchivedMessageCount();
      _state._restoreComposerDraft(
        sessionNotifier.getSession(_state.widget.sessionId),
        force: true,
      );
      _state._scheduleScrollToLatest(force: true);
      unawaited(_state._ensureArchivedMessageHistoryAccessible());
      await _state._maybeAutoApprovePendingTools();
      refreshSessionContextInBackground(sessionNotifier);
      _state.ref
          .read(socketStateProvider.notifier)
          .subscribeToSession(_state.widget.sessionId);
      _state._startMessagePolling();
    } finally {
      if (requiresBlockingLoad) {
        _state._setSessionRefreshing(false);
      }
      _state._initialLoadComplete = true;
      totalWatch.stop();
      Logger.info(
        '[SessionEntry] load complete session=${_state.widget.sessionId} '
        'blocking=$requiresBlockingLoad '
        'cached=$hasCachedMessageSnapshot '
        'messages=${_state._messages.length} '
        'cost=${totalWatch.elapsedMilliseconds}ms',
      );
    }
  }
}
