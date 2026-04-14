part of 'session_screen.dart';

class _SessionViewportController {
  static const double _historyEdgeLoadTrigger = 220.0;
  static const double _historyEdgeLoadTriggerViewportFactor = 0.78;
  static const double _edgeAutoloadRearmGap = 180.0;
  static const Duration _edgeAutoloadCooldown = Duration(milliseconds: 480);

  _SessionViewportController(this._state);

  final _SessionScreenState _state;

  bool _viewportUpdateScheduled = false;
  bool _scrollToLatestScheduled = false;
  bool _edgeOlderHistoryAccessInFlight = false;
  bool _edgeNewerHistoryAccessInFlight = false;
  bool _topEdgeAutoloadArmed = true;
  bool _bottomEdgeAutoloadArmed = true;
  int _scrollToLatestRequestId = 0;
  int _programmaticScrollActivity = 0;
  DateTime? _edgeAutoloadSuspendedUntil;
  String? _lastTopEdgeDiagnostic;
  String? _lastBottomEdgeDiagnostic;
  String? _lastMetricsDiagnostic;
  double? _lastObservedScrollPixels;
  double _lastObservedScrollDelta = 0;
  String _lastObservedScrollTrend = 'idle';
  String? _lastCompletedEdgeLoadDirection;
  DateTime? _lastCompletedEdgeLoadAt;
  int? _lastCompletedEdgeLoadWindowStart;

  int get programmaticScrollActivity => _programmaticScrollActivity;

  bool get _edgeAutoloadSuspended {
    final suspendedUntil = _edgeAutoloadSuspendedUntil;
    return suspendedUntil != null && DateTime.now().isBefore(suspendedUntil);
  }

  bool get _isTrendingOlder => _lastObservedScrollTrend == 'older';

  bool get _isTrendingNewer => _lastObservedScrollTrend == 'newer';

  String debugEdgeLoadStateSummary() {
    final lastLoadAt = _lastCompletedEdgeLoadAt?.toIso8601String() ?? 'na';
    final lastLoadDirection = _lastCompletedEdgeLoadDirection ?? 'none';
    final lastLoadStart = _lastCompletedEdgeLoadWindowStart?.toString() ?? 'na';
    return 'edgeState(trend=$_lastObservedScrollTrend '
        'topArmed=$_topEdgeAutoloadArmed bottomArmed=$_bottomEdgeAutoloadArmed '
        'delta=${_lastObservedScrollDelta.toStringAsFixed(1)} '
        'lastLoad=$lastLoadDirection lastLoadAt=$lastLoadAt '
        'lastLoadStart=$lastLoadStart)';
  }

  double _edgeLoadTriggerFor(ScrollPosition position) {
    final viewport = position.viewportDimension;
    if (!viewport.isFinite || viewport <= 0) {
      return _historyEdgeLoadTrigger;
    }
    final scaledTrigger = viewport * _historyEdgeLoadTriggerViewportFactor;
    return scaledTrigger > _historyEdgeLoadTrigger
        ? scaledTrigger
        : _historyEdgeLoadTrigger;
  }

  void _refreshEdgeAutoloadArming(ScrollPosition position) {
    final trigger = _edgeLoadTriggerFor(position);
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    if (!_topEdgeAutoloadArmed &&
        position.pixels > trigger + _edgeAutoloadRearmGap) {
      _topEdgeAutoloadArmed = true;
    }
    if (!_bottomEdgeAutoloadArmed &&
        distanceToBottom > trigger + _edgeAutoloadRearmGap) {
      _bottomEdgeAutoloadArmed = true;
    }
  }

  void recordEdgeLoadCompleted(String direction) {
    _lastCompletedEdgeLoadDirection = direction;
    _lastCompletedEdgeLoadAt = DateTime.now();
    _lastCompletedEdgeLoadWindowStart = _state._messageWindowStartIndex;
    // Re-arm autoload after edge load with a short cooldown.
    // Without this, the user can get stuck at the top of the content:
    // alignToBottom:false anchor restore places them near the top,
    // and the disarmed autoload can't re-arm because the user can't
    // scroll far enough below the trigger to satisfy the re-arm gap.
    _suspendEdgeAutoload(duration: const Duration(milliseconds: 200));
    if (direction.contains('older')) {
      _topEdgeAutoloadArmed = true;
    } else {
      _bottomEdgeAutoloadArmed = true;
    }
    Logger.info(
      '[SessionEdgeDiag] load-complete direction=$direction '
      'session=${_state.widget.sessionId} ${debugEdgeLoadStateSummary()} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
  }

  void _recordScrollObservation(ScrollPosition position) {
    final previousPixels = _lastObservedScrollPixels;
    _lastObservedScrollPixels = position.pixels;
    if (previousPixels == null) {
      return;
    }
    final delta = position.pixels - previousPixels;
    if (!delta.isFinite || delta.abs() < 0.5) {
      return;
    }
    _lastObservedScrollDelta = delta;
    _lastObservedScrollTrend = delta < 0 ? 'older' : 'newer';
  }

  void _suspendEdgeAutoload({
    Duration duration = _edgeAutoloadCooldown,
  }) {
    _edgeAutoloadSuspendedUntil = DateTime.now().add(duration);
    Logger.info(
      '[SessionArchive] edge-autoload suspended session=${_state.widget.sessionId} '
      'until=${_edgeAutoloadSuspendedUntil!.toIso8601String()} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
  }

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
        Logger.info(
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
        'from=${_state._scrollController.position.pixels.toStringAsFixed(1)}',
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
    final position = _state._scrollController.position;
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

    final refreshedPosition = _state._scrollController.position;
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
      Logger.info(
        '[ScrollDiag] scrollToLatestUntilSettled SKIP '
        'mounted=${_state.mounted} hasClients=${_state._scrollController.hasClients} '
        'requestId=$requestId',
      );
      return;
    }
    if (_state._hasScrolledToLatest && !force) {
      Logger.info(
        '[ScrollDiag] scrollToLatestUntilSettled SKIP already-at-latest '
        'requestId=$requestId animate=$animate force=$force',
      );
      return;
    }
    Logger.info(
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

      for (var attempt = 0; attempt < 8; attempt++) {
        attemptCount = attempt + 1;
        if (!_state.mounted ||
            !_state._scrollController.hasClients ||
            requestId != _scrollToLatestRequestId) {
          return;
        }

        final position = _state._scrollController.position;
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

        final settledPosition = _state._scrollController.position;
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
        'final=${_state._scrollController.position.pixels.toStringAsFixed(1)} '
        'max=${_state._scrollController.position.maxScrollExtent.toStringAsFixed(1)} '
        'cost=${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

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
        Logger.info(
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
    final target = _state._scrollController.position.minScrollExtent;
    if ((_state._scrollController.position.pixels - target).abs() < 1) {
      return;
    }
    Logger.info(
      '[SessionPerf][scroll-top] session=${_state.widget.sessionId} '
      'from=${_state._scrollController.position.pixels.toStringAsFixed(1)} '
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
    Logger.info(
      '[SessionArchive] scroll-top boundary-start session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
    final loaded = await _state._loadEarliestArchivedMessages(
      adjustScrollAfterLoad: false,
    );
    if (!loaded || !_state.mounted) {
      Logger.info(
        '[SessionArchive] scroll-top boundary-fallback session=${_state.widget.sessionId} '
        'loaded=$loaded ${_state._debugMessageWindowSummary()} '
        '${_state._debugScrollSummary()}',
      );
      if (_state._scrollController.hasClients) {
        final target = _state._scrollController.position.minScrollExtent;
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
      final target = _state._scrollController.position.minScrollExtent;
      if ((_state._scrollController.position.pixels - target).abs() >= 1) {
        _state._scrollController.jumpTo(target);
      }
      handleScrollMetricsChanged();
      Logger.info(
        '[SessionArchive] scroll-top boundary-end session=${_state.widget.sessionId} '
        '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
        '${_state._debugVisibleMessageSummary()}',
      );
    });
  }

  Future<void> _scrollToLatestHistoryBoundary() async {
    _suspendEdgeAutoload();
    Logger.info(
      '[SessionArchive] scroll-bottom boundary-start session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
    final loaded = await _state._loadLatestArchivedMessages(
      adjustScrollAfterLoad: false,
    );
    if (!loaded || !_state.mounted) {
      Logger.info(
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
      final target = _state._scrollController.position.maxScrollExtent;
      if ((_state._scrollController.position.pixels - target).abs() >= 1) {
        _state._scrollController.jumpTo(target);
      }
      handleScrollMetricsChanged();
      Logger.info(
        '[SessionArchive] scroll-bottom boundary-end session=${_state.widget.sessionId} '
        '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
        '${_state._debugVisibleMessageSummary()}',
      );
    });
  }

  void _maybeContinueHistoryFromTopEdge(ScrollPosition position) {
    final topEdgeTrigger = _edgeLoadTriggerFor(position);
    final isNearTopEdge = position.pixels <= topEdgeTrigger;
    final blockReason = _topEdgeBlockReason(position);
    if (blockReason != null) {
      if (isNearTopEdge) {
        _logTopEdgeDiagnostic(blockReason);
      }
      return;
    }
    if (!_state._hasOlderMessages &&
        (_state._hasCompleteArchivedMessageHistory ||
            _state._totalMessageCount <= _state._messages.length)) {
      if (isNearTopEdge) {
        _logTopEdgeDiagnostic('no-older-flag');
      }
      return;
    }
    _logTopEdgeDiagnostic('eligible');
    _topEdgeAutoloadArmed = false;
    _edgeOlderHistoryAccessInFlight = true;
    Logger.info(
      '[ScrollDiag] top-edge-LOAD-TRIGGERED session=${_state.widget.sessionId} '
      'pixels=${position.pixels.toStringAsFixed(1)} '
      'trigger=${topEdgeTrigger.toStringAsFixed(1)} '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    unawaited(() async {
      try {
        Logger.info(
          '[SessionArchive] top-edge trigger session=${_state.widget.sessionId} '
          'start=${_state._messageWindowStartIndex} loaded=${_state._messages.length} '
          'total=${_state._totalMessageCount} complete=${_state._hasCompleteArchivedMessageHistory} '
          '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
        );
        final ready = _state._hasLocallyAccessibleOlderArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        Logger.info(
          '[SessionArchive] top-edge ready session=${_state.widget.sessionId} '
          'ready=$ready hasOlder=${_state._hasOlderMessages} '
          'start=${_state._messageWindowStartIndex} ${_state._debugScrollSummary()} '
          '${debugEdgeLoadStateSummary()}',
        );
        if (!ready || !_state.mounted) {
          return;
        }
        if (_state._hasOlderMessages) {
          await _state._loadOlderArchivedMessages();
        }
      } finally {
        _edgeOlderHistoryAccessInFlight = false;
      }
    }());
  }

  void _maybeContinueHistoryFromBottomEdge(ScrollPosition position) {
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    final bottomEdgeTrigger = _edgeLoadTriggerFor(position);
    final isNearBottomEdge = distanceToBottom <= bottomEdgeTrigger;
    final blockReason = _bottomEdgeBlockReason(distanceToBottom);
    if (blockReason != null) {
      if (isNearBottomEdge) {
        _logBottomEdgeDiagnostic(blockReason);
      }
      return;
    }
    if (!_state._hasNewerMessages &&
        (_state._hasCompleteArchivedMessageHistory ||
            _state._totalMessageCount <= _state._messages.length)) {
      if (isNearBottomEdge) {
        _logBottomEdgeDiagnostic('no-newer-flag');
      }
      return;
    }
    _logBottomEdgeDiagnostic('eligible');
    _bottomEdgeAutoloadArmed = false;
    _edgeNewerHistoryAccessInFlight = true;
    Logger.info(
      '[ScrollDiag] bottom-edge-LOAD-TRIGGERED session=${_state.widget.sessionId} '
      'distanceToBottom=${distanceToBottom.toStringAsFixed(1)} '
      'trigger=${bottomEdgeTrigger.toStringAsFixed(1)} '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    unawaited(() async {
      try {
        Logger.info(
          '[SessionArchive] bottom-edge trigger session=${_state.widget.sessionId} '
          'start=${_state._messageWindowStartIndex} loaded=${_state._messages.length} '
          'total=${_state._totalMessageCount} complete=${_state._hasCompleteArchivedMessageHistory} '
          '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
        );
        final ready = _state._hasLocallyAccessibleNewerArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        Logger.info(
          '[SessionArchive] bottom-edge ready session=${_state.widget.sessionId} '
          'ready=$ready hasNewer=${_state._hasNewerMessages} '
          'start=${_state._messageWindowStartIndex} ${_state._debugScrollSummary()} '
          '${debugEdgeLoadStateSummary()}',
        );
        if (!ready || !_state.mounted) {
          return;
        }
        if (_state._hasNewerMessages) {
          await _state._loadNewerArchivedMessages();
        }
      } finally {
        _edgeNewerHistoryAccessInFlight = false;
      }
    }());
  }

  String? _topEdgeBlockReason(ScrollPosition position) {
    final trigger = _edgeLoadTriggerFor(position);
    if (_edgeOlderHistoryAccessInFlight) {
      return 'older-inflight';
    }
    if (_state._isLoadingOlderMessages) {
      return 'older-loading';
    }
    if (_programmaticScrollActivity != 0) {
      return 'programmatic-scroll';
    }
    if (_edgeAutoloadSuspended) {
      return 'autoload-suspended';
    }
    if (!_state._messageViewportReady) {
      return 'viewport-not-ready';
    }
    if (!_topEdgeAutoloadArmed) {
      return 'older-not-rearmed';
    }
    if (_isTrendingNewer) {
      return 'scroll-trend-newer';
    }
    if (position.pixels > trigger) {
      return 'not-near-top-edge';
    }
    return null;
  }

  String? _bottomEdgeBlockReason(double distanceToBottom) {
    final position = _state._scrollController.hasClients
        ? _state._scrollController.position
        : null;
    final trigger = position == null
        ? _historyEdgeLoadTrigger
        : _edgeLoadTriggerFor(position);
    if (_edgeNewerHistoryAccessInFlight) {
      return 'newer-inflight';
    }
    if (_state._isLoadingNewerMessages) {
      return 'newer-loading';
    }
    if (_programmaticScrollActivity != 0) {
      return 'programmatic-scroll';
    }
    if (_edgeAutoloadSuspended) {
      return 'autoload-suspended';
    }
    if (!_state._messageViewportReady) {
      return 'viewport-not-ready';
    }
    if (!_bottomEdgeAutoloadArmed) {
      return 'newer-not-rearmed';
    }
    if (_isTrendingOlder) {
      return 'scroll-trend-older';
    }
    if (distanceToBottom > trigger) {
      return 'not-near-bottom-edge';
    }
    return null;
  }

  void _logTopEdgeDiagnostic(String reason) {
    final next =
        '$reason|${_state._messageWindowStartIndex}|${_state._messages.length}';
    if (_lastTopEdgeDiagnostic == next) {
      return;
    }
    _lastTopEdgeDiagnostic = next;
    Logger.info(
      '[SessionEdgeDiag] top-edge reason=$reason '
      'session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
      '${_state._debugVisibleMessageSummary()} ${_state._debugArchiveAccessSummary()} '
      '${debugEdgeLoadStateSummary()}',
    );
  }

  void _logBottomEdgeDiagnostic(String reason) {
    final next =
        '$reason|${_state._messageWindowStartIndex}|${_state._messages.length}';
    if (_lastBottomEdgeDiagnostic == next) {
      return;
    }
    _lastBottomEdgeDiagnostic = next;
    Logger.info(
      '[SessionEdgeDiag] bottom-edge reason=$reason '
      'session=${_state.widget.sessionId} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
      '${_state._debugVisibleMessageSummary()} ${_state._debugArchiveAccessSummary()} '
      '${debugEdgeLoadStateSummary()}',
    );
  }

  void _logScrollMetricsDiagnostic(ScrollPosition position) {
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    final isNearInterestingEdge =
        position.pixels <= 320 || distanceToBottom <= 320;
    if (!isNearInterestingEdge) {
      return;
    }
    final next =
        'offset=${(position.pixels / 24).floor()}|bottom=${(distanceToBottom / 24).floor()}|'
        'start=${_state._messageWindowStartIndex}|loaded=${_state._messages.length}|'
        'older=${_state._hasOlderMessages}|newer=${_state._hasNewerMessages}|'
        'prog=$_programmaticScrollActivity|'
        'dir=${position.userScrollDirection.name}';
    if (_lastMetricsDiagnostic == next) {
      return;
    }
    _lastMetricsDiagnostic = next;
    Logger.info(
      '[SessionEdgeDiag] metrics session=${_state.widget.sessionId} '
      'dir=${position.userScrollDirection.name} '
      'outOfRange=${position.outOfRange} '
      'atEdge=${position.atEdge} '
      'extentBefore=${position.extentBefore.toStringAsFixed(1)} '
      'extentInside=${position.extentInside.toStringAsFixed(1)} '
      'extentAfter=${position.extentAfter.toStringAsFixed(1)} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()} '
      '${_state._debugArchiveAccessSummary()} ${debugEdgeLoadStateSummary()}',
    );
  }

  void scheduleViewportStateRefresh() {
    if (_viewportUpdateScheduled) {
      return;
    }
    _viewportUpdateScheduled = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_state.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewportUpdateScheduled = false;
        _state._refreshStickyTurnPrompt();
      });
    });
  }

  double? captureScrollPositionRatio() {
    if (!_state._scrollController.hasClients) {
      return null;
    }
    final position = _state._scrollController.position;
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

      final position = _state._scrollController.position;
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
      }

      final finalTarget = position.pixels.clamp(
        position.minScrollExtent,
        maxScroll,
      );
      if ((position.pixels - finalTarget).abs() >= 1) {
        _state._scrollController.jumpTo(finalTarget);
      }

      handleScrollMetricsChanged();
    });
  }

  void handleScrollMetricsChanged() {
    if (!_state._scrollController.hasClients) {
      return;
    }
    final position = _state._scrollController.position;
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
        _state._hasScrolledToLatest) {
      _state._userHasScrolledUp = true;
      Logger.info(
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
      Logger.info(
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
    final edgeLoading = _state._isLoadingOlderMessages ||
        _state._isLoadingNewerMessages;
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
      Logger.info(
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
