part of '../session_detail.dart';

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
      // Use force: false for warm refresh to avoid overwriting text the user
      // may have started typing since the page opened.
      _state._restoreComposerDraft(loadedSession, force: false);
      if (loadedSession == null) {
        return;
      }
      // If the user has already scrolled up to browse history (edge load),
      // don't replace the message window — it would jump their viewport.
      // The message window will be refreshed next time they scroll to latest.
      if (_state._userHasScrolledUp ||
          _state._hasNewerMessages ||
          _state._isLoadingOlderMessages ||
          _state._isLoadingNewerMessages ||
          _state._viewportController.programmaticScrollActivity != 0) {
        Logger.info(
          '[SessionEntry] warm-refresh skipped — user browsing history '
          'session=${_state.widget.sessionId} '
          'userScrolledUp=${_state._userHasScrolledUp} '
          'hasNewer=${_state._hasNewerMessages} '
          'loadingOlder=${_state._isLoadingOlderMessages} '
          'loadingNewer=${_state._isLoadingNewerMessages} '
          'prog=${_state._viewportController.programmaticScrollActivity}',
        );
      } else {
        try {
          final messageLoadWatch = Stopwatch()..start();
          await sessionNotifier.loadSessionMessages(
            _state.widget.sessionId,
            force: true,
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
}
