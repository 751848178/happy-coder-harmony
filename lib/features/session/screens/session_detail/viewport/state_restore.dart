part of '../session_detail.dart';

extension _SessionViewportStateRestore on _SessionViewportController {
  void scheduleViewportStateRefresh() {
    if (_viewportUpdateScheduled) {
      return;
    }
    _viewportUpdateScheduled = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_state.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_state._scrollController.hasClients) {
          // Window shifts and anchor restores can leave scroll offset
          // unchanged, so ScrollController listeners won't fire even though
          // the accessible history boundary semantics did change.
          handleScrollMetricsChanged();
        }
        _state._refreshStickyTurnPrompt();
        _viewportUpdateScheduled = false;
      });
    });
  }

  double? captureScrollPositionRatio() {
    if (!_state._scrollController.hasClients) {
      return null;
    }
    final position = _state._scrollController.effectivePosition;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) {
      return null;
    }
    return position.pixels / maxScroll;
  }

  void scheduleRestoreScrollPosition({
    double? scrollRatio,
    bool forcePinToLatest = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_state.mounted || !_state._scrollController.hasClients) {
        return;
      }

      final position = _state._scrollController.effectivePosition;
      final maxScroll = position.maxScrollExtent;

      if (forcePinToLatest) {
        final alreadyAtBottom = (position.pixels - maxScroll).abs() < 1;
        if (!alreadyAtBottom) {
          scheduleScrollToLatest(force: true);
        }
        return;
      }

      if (scrollRatio != null && maxScroll > 0) {
        final targetOffset = scrollRatio * maxScroll;
        final clampedTarget = targetOffset.clamp(
          position.minScrollExtent,
          maxScroll,
        );
        if ((position.pixels - clampedTarget).abs() >= 1) {
          _state._scrollController.jumpTo(clampedTarget);
        }
      } else {
        // Safety clamp: ensure pixels is within valid range after layout.
        final clamped = position.pixels.clamp(
          position.minScrollExtent,
          maxScroll,
        );
        if ((position.pixels - clamped).abs() >= 1) {
          _state._scrollController.jumpTo(clamped);
        }
      }

      handleScrollMetricsChanged();
    });
  }

  void handleScrollMetricsChanged() {
    if (!_state._scrollController.hasClients) {
      return;
    }
    final position = _state._scrollController.effectivePosition;
    _state._markMessageListScrollActivity();
    _recordScrollObservation(position);
    _refreshEdgeAutoloadArming(position);
    _logScrollMetricsDiagnostic(position);
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    final hasOlderHistory = _state._hasOlderMessages;
    final hasNewerHistory = _state._hasNewerMessages;
    final nextCanScrollToTop = position.pixels > 32 || hasOlderHistory;
    final nextCanScrollToBottom = distanceToBottom > 32 || hasNewerHistory;
    final nextIsNearBottom = distanceToBottom < 72;
    final nextShouldStickToLatest = distanceToBottom <= 8;
    _maybeContinueHistoryFromTopEdge(position);
    _maybeContinueHistoryFromBottomEdge(position);
    if (distanceToBottom > 72 &&
        !_state._userHasScrolledUp &&
        _state._hasScrolledToLatest &&
        !_state._isLoadingOlderMessages &&
        !_state._isLoadingNewerMessages &&
        _isTrendingOlder) {
      _state._userHasScrolledUp = true;
      Logger.debug(
        '[ScrollDiag] userScrolledUp -> true session=${_state.widget.sessionId} '
        'distanceToBottom=${distanceToBottom.toStringAsFixed(1)} '
        '${_state._debugScrollSummary()}',
      );
    }
    if (nextShouldStickToLatest &&
        _state._userHasScrolledUp &&
        !_state._isLoadingOlderMessages &&
        !_state._isLoadingNewerMessages) {
      _state._userHasScrolledUp = false;
      Logger.debug(
        '[ScrollDiag] userScrolledUp -> false session=${_state.widget.sessionId} '
        'distanceToBottom=${distanceToBottom.toStringAsFixed(1)} '
        '${_state._debugScrollSummary()}',
      );
    }
    final shouldUpdate = nextCanScrollToTop != _state._canScrollToTop ||
        nextCanScrollToBottom != _state._canScrollToBottom ||
        nextIsNearBottom != _state._isNearBottom ||
        nextShouldStickToLatest != _state._shouldStickToLatest;
    // Skip sticky prompt refresh during edge loading — the content is
    // being replaced and the render tree is in flux.  Refreshing now is
    // wasteful and can trigger getOffsetToReveal exceptions.
    final edgeLoading =
        _state._isLoadingOlderMessages || _state._isLoadingNewerMessages;
    if (_programmaticScrollActivity == 0 &&
        !edgeLoading &&
        (_state._cachedHasStickyCandidates || _state._stickyTurnId != null)) {
      scheduleViewportStateRefresh();
    }
    if (!shouldUpdate) {
      return;
    }
    if (!_state.mounted) {
      return;
    }
    if (_state._canScrollToBottom != nextCanScrollToBottom ||
        _state._shouldStickToLatest != nextShouldStickToLatest) {
      Logger.debug(
        '[ScrollDiag] state-change session=${_state.widget.sessionId} '
        'canScrollDown: ${_state._canScrollToBottom} -> $nextCanScrollToBottom '
        'canScrollUp: ${_state._canScrollToTop} -> $nextCanScrollToTop '
        'stickToLatest: ${_state._shouldStickToLatest} -> $nextShouldStickToLatest '
        'nearBottom: ${_state._isNearBottom} -> $nextIsNearBottom '
        'userScrolledUp: ${_state._userHasScrolledUp} '
        'hasScrolledToLatest: ${_state._hasScrolledToLatest} '
        'distanceToBottom=${distanceToBottom.toStringAsFixed(1)} '
        'hasNewerHistory=$hasNewerHistory hasOlderHistory=$hasOlderHistory '
        'prog=$_programmaticScrollActivity',
      );
    }
    _state._canScrollToTopN.value = nextCanScrollToTop;
    _state._canScrollToBottomN.value = nextCanScrollToBottom;
    _state._isNearBottomN.value = nextIsNearBottom;
    _state._shouldStickToLatestN.value = nextShouldStickToLatest;
    if (nextIsNearBottom) {
      _state._hasUnreadMessagesN.value = false;
    }
  }
}
