part of '../session_detail.dart';

extension _SessionViewportScrollCommands on _SessionViewportController {
  void scrollToBottom() {
    Logger.info(
      '[ScrollDiag] scrollToBottom TAPPED session=${_state.widget.sessionId} '
      'hasNewer=${_state._hasNewerMessages} '
      'hasOlder=${_state._hasOlderMessages} '
      'userScrolledUp=$_state._userHasScrolledUp '
      'hasScrolledToLatest=$_state._hasScrolledToLatest '
      'shouldStick=$_state._shouldStickToLatest '
      'canScrollDown=$_state._canScrollToBottom '
      'progActivity=$_programmaticScrollActivity '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    _state._userHasScrolledUp = false;
    if (_state._hasNewerMessages) {
      unawaited(() async {
        Logger.debug(
          '[SessionArchive] scroll-bottom request session=${_state.widget.sessionId} '
          'complete=${_state._hasCompleteArchivedMessageHistory} '
          'hasNewer=${_state._hasNewerMessages} '
          'start=${_state._messageWindowStartIndex} '
          '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
        );
        final ready = _state._hasLocallyAccessibleNewerArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        if (!ready || !_state.mounted || !_state._hasNewerMessages) {
          if (_state.mounted) {
            handleScrollMetricsChanged();
          }
          return;
        }
        if (_state._hasLocallyAccessibleNewerArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory) {
          await _scrollToLatestHistoryBoundary();
        }
      }());
      return;
    }
    if (_state._scrollController.hasClients) {
      Logger.info(
        '[SessionPerf][scroll-bottom] session=${_state.widget.sessionId} '
        'from=${_state._scrollController.effectivePosition.pixels.toStringAsFixed(1)}',
      );
    }
    scheduleScrollToLatest(animate: true, force: true);
  }

  void scheduleScrollToLatest({
    bool animate = false,
    bool force = false,
  }) {
    if (_scrollToLatestScheduled && !force) {
      return;
    }
    _scrollToLatestScheduled = true;
    final requestId = ++_scrollToLatestRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatestScheduled = false;
      unawaited(
        _scrollToLatestUntilSettled(
          requestId,
          animate: animate,
          force: force,
        ),
      );
    });
  }

  Future<void> runProgrammaticScroll(
    Future<void> Function() action,
  ) async {
    _state._pauseMessageInteractions();
    _programmaticScrollActivity += 1;
    try {
      await action();
    } finally {
      if (_programmaticScrollActivity > 0) {
        _programmaticScrollActivity -= 1;
      }
      if (_programmaticScrollActivity == 0 && _state.mounted) {
        scheduleViewportStateRefresh();
        _state._scheduleMessageInteractionsIdleEnable();
      }
    }
  }

  Future<void> animateToTargetWithShortTail(double target) async {
    if (!_state.mounted || !_state._scrollController.hasClients) {
      return;
    }
    final position = _state._scrollController.effectivePosition;
    final current = position.pixels;
    final distance = (current - target).abs();
    final viewport =
        position.viewportDimension <= 0 ? 1.0 : position.viewportDimension;
    final jumpThreshold = viewport * _sessionLongScrollJumpThresholdViewports;
    final stopwatch = Stopwatch()..start();
    var usedIntermediateJump = false;

    if (distance > jumpThreshold) {
      usedIntermediateJump = true;
      final tailDistance = viewport * _sessionLongScrollAnimatedTailViewports;
      final intermediateTarget =
          target > current ? target - tailDistance : target + tailDistance;
      final clampedIntermediate = intermediateTarget.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      final intermediate = (clampedIntermediate as num).toDouble();
      if ((intermediate - current).abs() >= 1) {
        _state._scrollController.jumpTo(intermediate);
        await SchedulerBinding.instance.endOfFrame;
      }
      if (!_state.mounted || !_state._scrollController.hasClients) {
        return;
      }
    }

    final refreshedPosition = _state._scrollController.effectivePosition;
    final refreshedTarget = target.clamp(
      refreshedPosition.minScrollExtent,
      refreshedPosition.maxScrollExtent,
    );
    final destination = (refreshedTarget as num).toDouble();
    if ((refreshedPosition.pixels - destination).abs() < 1) {
      stopwatch.stop();
      return;
    }
    await _state._scrollController.animateTo(
      destination,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    stopwatch.stop();
    if (_sessionVerbosePerfLogging) {
      Logger.info(
        '[SessionPerf][scroll-tail] session=${_state.widget.sessionId} '
        'from=${current.toStringAsFixed(1)} '
        'to=${destination.toStringAsFixed(1)} '
        'distance=${distance.toStringAsFixed(1)} '
        'viewport=${viewport.toStringAsFixed(1)} '
        'jumped=$usedIntermediateJump '
        'cost=${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<void> _scrollToLatestUntilSettled(
    int requestId, {
    required bool animate,
    required bool force,
  }) async {
    if (!_state.mounted || !_state._scrollController.hasClients) {
      Logger.debug(
        '[ScrollDiag] scrollToLatestUntilSettled SKIP '
        'mounted=${_state.mounted} hasClients=${_state._scrollController.hasClients} '
        'requestId=$requestId',
      );
      return;
    }
    if (_state._hasScrolledToLatest && !force) {
      Logger.debug(
        '[ScrollDiag] scrollToLatestUntilSettled SKIP already-at-latest '
        'requestId=$requestId animate=$animate force=$force',
      );
      return;
    }
    Logger.debug(
      '[ScrollDiag] scrollToLatestUntilSettled START '
      'requestId=$requestId animate=$animate force=$force '
      '${_state._debugScrollSummary()}',
    );

    final stopwatch = Stopwatch()..start();
    var attemptCount = 0;
    await runProgrammaticScroll(() async {
      var previousMaxScrollExtent = -1.0;
      var animated = false;
      var revealedViewport = _state._messageViewportReady;

      for (var attempt = 0; attempt < 16; attempt++) {
        attemptCount = attempt + 1;
        // Time-based exit: stop retrying after 500ms regardless of settle
        // state.  During rapid streaming, maxScrollExtent keeps growing and
        // the settle loop would exhaust a fixed attempt count without ever
        // settling.  A time budget gracefully exits and lets the next
        // scheduleScrollToLatest (from the 150ms socket debounce) continue.
        if (stopwatch.elapsedMilliseconds > 500) {
          break;
        }
        if (!_state.mounted ||
            !_state._scrollController.hasClients ||
            requestId != _scrollToLatestRequestId) {
          return;
        }

        final position = _state._scrollController.effectivePosition;
        final target = position.maxScrollExtent;
        final alreadyAtLatest = (position.pixels - target).abs() < 1;

        if (!alreadyAtLatest) {
          if (animate && !animated) {
            animated = true;
            await animateToTargetWithShortTail(target);
          } else {
            _state._scrollController.jumpTo(target);
          }
        }

        if (!revealedViewport && _state.mounted) {
          _state._messageViewportReadyN.value = true;
          revealedViewport = true;
        }

        await SchedulerBinding.instance.endOfFrame;

        if (!_state.mounted ||
            !_state._scrollController.hasClients ||
            requestId != _scrollToLatestRequestId) {
          return;
        }

        final settledPosition = _state._scrollController.effectivePosition;
        final settledMaxScrollExtent = settledPosition.maxScrollExtent;
        final distanceToBottom =
            (settledPosition.pixels - settledMaxScrollExtent).abs();
        final extentStable =
            (settledMaxScrollExtent - previousMaxScrollExtent).abs() < 1;

        if (distanceToBottom < 1 && extentStable) {
          break;
        }
        previousMaxScrollExtent = settledMaxScrollExtent;
      }
    });

    if (!_state.mounted || requestId != _scrollToLatestRequestId) {
      return;
    }

    stopwatch.stop();
    if (!_state._messageViewportReady) {
      _state._messageViewportReadyN.value = true;
    }
    _state._shouldStickToLatestN.value = true;
    _state._hasUnreadMessagesN.value = false;
    _state._hasScrolledToLatest = true;
    handleScrollMetricsChanged();
    if (_sessionVerbosePerfLogging && _state._scrollController.hasClients) {
      Logger.info(
        '[SessionPerf][scroll-latest] session=${_state.widget.sessionId} '
        'animate=$animate force=$force attempts=$attemptCount '
        'final=${_state._scrollController.effectivePosition.pixels.toStringAsFixed(1)} '
        'max=${_state._scrollController.effectivePosition.maxScrollExtent.toStringAsFixed(1)} '
        'cost=${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }
}
