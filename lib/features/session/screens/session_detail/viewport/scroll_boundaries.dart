part of '../session_detail.dart';

extension _SessionViewportScrollBoundaries on _SessionViewportController {
  void scrollToTop() {
    if (!_state._scrollController.hasClients) {
      return;
    }
    Logger.info(
      '[ScrollDiag] scrollToTop TAPPED session=${_state.widget.sessionId} '
      'hasNewer=${_state._hasNewerMessages} '
      'hasOlder=${_state._hasOlderMessages} '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    _state._userHasScrolledUp = true;
    _state._shouldStickToLatestN.value = false;
    if (_state._hasOlderMessages) {
      unawaited(() async {
        Logger.debug(
          '[SessionArchive] scroll-top request session=${_state.widget.sessionId} '
          'complete=${_state._hasCompleteArchivedMessageHistory} '
          'hasOlder=${_state._hasOlderMessages} '
          'start=${_state._messageWindowStartIndex} '
          '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
        );
        final ready = _state._canJumpToEarliestArchivedBoundary ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        if (!ready || !_state.mounted || !_state._hasOlderMessages) {
          if (_state.mounted) {
            handleScrollMetricsChanged();
          }
          return;
        }
        if (_state._canJumpToEarliestArchivedBoundary ||
            _state._hasCompleteArchivedMessageHistory) {
          await _scrollToEarliestHistoryBoundary();
        }
      }());
      return;
    }
    final target = _state._scrollController.effectivePosition.minScrollExtent;
    if ((_state._scrollController.effectivePosition.pixels - target).abs() <
        1) {
      return;
    }
    Logger.info(
      '[SessionPerf][scroll-top] session=${_state.widget.sessionId} '
      'from=${_state._scrollController.effectivePosition.pixels.toStringAsFixed(1)} '
      'to=${target.toStringAsFixed(1)}',
    );
    unawaited(
      runProgrammaticScroll(() async {
        await animateToTargetWithShortTail(target);
        handleScrollMetricsChanged();
      }),
    );
  }

  Future<void> _scrollToEarliestHistoryBoundary() async {
    _suspendEdgeAutoload();
    Logger.debug(
      '[SessionArchive] scroll-top boundary-start session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
    final loaded = await _state._loadEarliestArchivedMessages(
      adjustScrollAfterLoad: false,
    );
    if (!loaded || !_state.mounted) {
      Logger.debug(
        '[SessionArchive] scroll-top boundary-fallback session=${_state.widget.sessionId} '
        'loaded=$loaded ${_state._debugMessageWindowSummary()} '
        '${_state._debugScrollSummary()}',
      );
      if (_state._scrollController.hasClients) {
        final target =
            _state._scrollController.effectivePosition.minScrollExtent;
        unawaited(
          runProgrammaticScroll(() => animateToTargetWithShortTail(target)),
        );
      }
      return;
    }

    await runProgrammaticScroll(() async {
      await SchedulerBinding.instance.endOfFrame;
      if (!_state.mounted || !_state._scrollController.hasClients) {
        return;
      }
      final target = _state._scrollController.effectivePosition.minScrollExtent;
      if ((_state._scrollController.effectivePosition.pixels - target).abs() >=
          1) {
        _state._scrollController.jumpTo(target);
      }
      handleScrollMetricsChanged();
      Logger.debug(
        '[SessionArchive] scroll-top boundary-end session=${_state.widget.sessionId} '
        '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
        '${_state._debugVisibleMessageSummary()}',
      );
    });
  }

  Future<void> _scrollToLatestHistoryBoundary() async {
    _suspendEdgeAutoload();
    Logger.debug(
      '[SessionArchive] scroll-bottom boundary-start session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
    final loaded = await _state._loadLatestArchivedMessages(
      adjustScrollAfterLoad: false,
    );
    if (!loaded || !_state.mounted) {
      Logger.debug(
        '[SessionArchive] scroll-bottom boundary-fallback session=${_state.widget.sessionId} '
        'loaded=$loaded ${_state._debugMessageWindowSummary()} '
        '${_state._debugScrollSummary()}',
      );
      scheduleScrollToLatest(animate: true, force: true);
      return;
    }

    await runProgrammaticScroll(() async {
      await SchedulerBinding.instance.endOfFrame;
      if (!_state.mounted || !_state._scrollController.hasClients) {
        return;
      }
      final target = _state._scrollController.effectivePosition.maxScrollExtent;
      if ((_state._scrollController.effectivePosition.pixels - target).abs() >=
          1) {
        _state._scrollController.jumpTo(target);
      }
      handleScrollMetricsChanged();
      Logger.debug(
        '[SessionArchive] scroll-bottom boundary-end session=${_state.widget.sessionId} '
        '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
        '${_state._debugVisibleMessageSummary()}',
      );
    });
  }
}
