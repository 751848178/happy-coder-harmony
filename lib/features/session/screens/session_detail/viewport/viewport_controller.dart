part of '../session_detail.dart';

class _SessionViewportController {
  static const double _historyEdgeLoadTrigger = 220.0;
  static const double _historyEdgeLoadTriggerViewportFactor = 1.0;
  static const double _historyEdgeLoadTriggerLeadMargin = 180.0;
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
    final scaledTrigger = viewport * _historyEdgeLoadTriggerViewportFactor +
        _historyEdgeLoadTriggerLeadMargin;
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
    Logger.debug(
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
    Logger.debug(
      '[SessionArchive] edge-autoload suspended session=${_state.widget.sessionId} '
      'until=${_edgeAutoloadSuspendedUntil!.toIso8601String()} '
      '${_state._debugMessageWindowSummary()} ${_state._debugScrollSummary()}',
    );
  }
}
