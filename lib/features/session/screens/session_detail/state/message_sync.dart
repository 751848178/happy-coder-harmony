part of '../session_detail.dart';

extension _SessionScreenMessageSync on _SessionScreenState {
  /// Subscribe to per-session message changes from the repository.
  void _subscribeToMessageChanges() {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    _messageChangeSub =
        sessionNotifier.messageChangesFor(widget.sessionId).listen((_) {
      if (!mounted) return;
      _scheduleMessageSync();
    });
  }

  /// Schedule a coalesced message sync at the end of the current microtask.
  /// Multiple rapid state emissions (common during initial load) are collapsed
  /// into a single _syncMessagesFromRepository call, preventing 4-5 redundant
  /// full-rebuild cascades.
  void _scheduleMessageSync() {
    if (_messageSyncScheduled) return;
    _messageSyncScheduled = true;
    scheduleMicrotask(() {
      _messageSyncScheduled = false;
      if (!mounted) return;
      _syncMessagesFromRepository();
    });
  }

  /// Read current messages from the repository and update local ValueNotifiers.
  void _syncMessagesFromRepository() {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final sessionMessages =
        sessionNotifier.getSessionMessages(widget.sessionId);
    final nextState = _SessionMessageViewState(
      messages: sessionMessages?.messages ?? const <ReducerMessage>[],
      hasLoadedMessages: sessionMessages?.isLoaded == true,
      totalMessageCount: sessionMessages?.totalMessageCount ?? 0,
      hasOlderMessages: sessionMessages?.hasOlderMessages == true,
      hasNewerMessages: sessionMessages?.hasNewerMessages == true,
      windowStartIndex: sessionMessages?.windowStartIndex ?? 0,
    );
    final previousState = _messageViewStateN.value;
    if (previousState == nextState) {
      return;
    }
    // When the user is near the bottom (or hasn't scrolled to latest yet),
    // activate standbyForAppend so that _ChatScrollPosition corrects the
    // scroll offset synchronously during the next layout pass.  This prevents
    // the one-frame blank-space flicker that occurs when new messages are
    // added below the viewport but the scroll position is corrected only
    // asynchronously via scheduleScrollToLatest.
    //
    // Skip during edge loads: the edge-load functions (loadOlder/loadNewer)
    // set their own standby mode (prepend or append) BEFORE calling this
    // method.  If we overwrote it here, a loadOlder's standbyForPrepend
    // would be replaced by standbyForAppend, causing the scroll to correct
    // in the wrong direction.
    if (nextState.hasLoadedMessages &&
        nextState.messages.isNotEmpty &&
        _scrollController.hasClients &&
        _scrollController._standbyPixels == null &&
        (_isNearBottom || !_hasScrolledToLatest) &&
        !nextState.hasNewerMessages &&
        !_isLoadingOlderMessages &&
        !_isLoadingNewerMessages) {
      _scrollController.standbyForAppend();
    }
    if (!nextState.hasLoadedMessages || nextState.messages.isEmpty) {
      _messageViewportReadyN.value = true;
    } else if (!previousState.hasLoadedMessages &&
        !nextState.hasNewerMessages &&
        !_hasScrolledToLatest &&
        !_userHasScrolledUp) {
      _messageViewportReadyN.value = false;
    }
    _messageViewStateN.value = nextState;
    _pruneMessageRenderCaches(nextState.messages);
    if (_collapseAllTurns &&
        nextState.hasLoadedMessages &&
        _collapsedTurnSummaries.isEmpty &&
        nextState.messages.isNotEmpty) {
      unawaited(
        _ensureCollapsedTurnSummariesLoaded(
          _resolveTurnGroups(nextState.messages),
        ),
      );
    }
    _logDuplicateMessageIds(nextState.messages, stage: 'message-sync');
    if (_sessionVerbosePerfLogging) {
      Logger.info(
        '[SessionPerf][message-sync] session=${widget.sessionId} '
        'loaded=${nextState.hasLoadedMessages} '
        'messages=${nextState.messages.length} '
        'total=${nextState.totalMessageCount} '
        'hasOlder=${nextState.hasOlderMessages} '
        'hasNewer=${nextState.hasNewerMessages} '
        'start=${nextState.windowStartIndex} '
        'prevLoaded=${previousState.hasLoadedMessages} '
        'prevMessages=${previousState.messages.length}',
      );
    }
    if (nextState.hasLoadedMessages &&
        nextState.totalMessageCount > nextState.messages.length &&
        _archivedMessageCount < nextState.totalMessageCount &&
        !_isHydratingArchiveHistory) {
      unawaited(_ensureArchivedMessageHistoryAccessible());
    }
    if (nextState.hasLoadedMessages && nextState.messages.isNotEmpty) {
      _scheduleMessageInteractionsIdleEnable();
    }
  }
}
