part of '../session_detail.dart';

extension _SessionScreenBlockingLoadCoordinator
    on _SessionScreenLoadCoordinator {
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
