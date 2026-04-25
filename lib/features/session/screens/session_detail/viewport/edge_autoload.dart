part of '../session_detail.dart';

extension _SessionViewportEdgeAutoload on _SessionViewportController {
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
    final beforeWindowStart = _state._messageWindowStartIndex;
    final beforeLoadedCount = _state._messages.length;
    _topEdgeAutoloadArmed = false;
    _edgeOlderHistoryAccessInFlight = true;
    Logger.debug(
      '[ScrollDiag] top-edge-LOAD-TRIGGERED session=${_state.widget.sessionId} '
      'pixels=${position.pixels.toStringAsFixed(1)} '
      'trigger=${topEdgeTrigger.toStringAsFixed(1)} '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    unawaited(() async {
      try {
        Logger.debug(
          '[SessionArchive] top-edge trigger session=${_state.widget.sessionId} '
          'start=${_state._messageWindowStartIndex} loaded=${_state._messages.length} '
          'total=${_state._totalMessageCount} complete=${_state._hasCompleteArchivedMessageHistory} '
          '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
        );
        final ready = _state._hasLocallyAccessibleOlderArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        Logger.debug(
          '[SessionArchive] top-edge ready session=${_state.widget.sessionId} '
          'ready=$ready hasOlder=${_state._hasOlderMessages} '
          'start=${_state._messageWindowStartIndex} ${_state._debugScrollSummary()} '
          '${debugEdgeLoadStateSummary()}',
        );
        if (!ready || !_state.mounted) {
          _rearmTopEdgeAutoloadIfWindowUnchanged(
            beforeWindowStart: beforeWindowStart,
            beforeLoadedCount: beforeLoadedCount,
            reason: ready ? 'top-edge-unmounted' : 'top-edge-not-ready',
          );
          return;
        }
        if (_state._hasOlderMessages) {
          await _state._loadOlderArchivedMessages();
        } else {
          _rearmTopEdgeAutoloadIfWindowUnchanged(
            beforeWindowStart: beforeWindowStart,
            beforeLoadedCount: beforeLoadedCount,
            reason: 'top-edge-no-older-after-ready',
          );
        }
      } finally {
        _edgeOlderHistoryAccessInFlight = false;
        _rearmTopEdgeAutoloadIfWindowUnchanged(
          beforeWindowStart: beforeWindowStart,
          beforeLoadedCount: beforeLoadedCount,
          reason: 'top-edge-no-progress',
        );
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
    final beforeWindowStart = _state._messageWindowStartIndex;
    final beforeLoadedCount = _state._messages.length;
    _bottomEdgeAutoloadArmed = false;
    _edgeNewerHistoryAccessInFlight = true;
    Logger.debug(
      '[ScrollDiag] bottom-edge-LOAD-TRIGGERED session=${_state.widget.sessionId} '
      'distanceToBottom=${distanceToBottom.toStringAsFixed(1)} '
      'trigger=${bottomEdgeTrigger.toStringAsFixed(1)} '
      '${_state._debugScrollSummary()} ${_state._debugMessageWindowSummary()}',
    );
    unawaited(() async {
      try {
        Logger.debug(
          '[SessionArchive] bottom-edge trigger session=${_state.widget.sessionId} '
          'start=${_state._messageWindowStartIndex} loaded=${_state._messages.length} '
          'total=${_state._totalMessageCount} complete=${_state._hasCompleteArchivedMessageHistory} '
          '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
        );
        final ready = _state._hasLocallyAccessibleNewerArchivedMessages ||
            _state._hasCompleteArchivedMessageHistory ||
            await _state._awaitArchivedMessageHistoryAccessible();
        Logger.debug(
          '[SessionArchive] bottom-edge ready session=${_state.widget.sessionId} '
          'ready=$ready hasNewer=${_state._hasNewerMessages} '
          'start=${_state._messageWindowStartIndex} ${_state._debugScrollSummary()} '
          '${debugEdgeLoadStateSummary()}',
        );
        if (!ready || !_state.mounted) {
          _rearmBottomEdgeAutoloadIfWindowUnchanged(
            beforeWindowStart: beforeWindowStart,
            beforeLoadedCount: beforeLoadedCount,
            reason: ready ? 'bottom-edge-unmounted' : 'bottom-edge-not-ready',
          );
          return;
        }
        if (_state._hasNewerMessages) {
          await _state._loadNewerArchivedMessages();
        } else {
          _rearmBottomEdgeAutoloadIfWindowUnchanged(
            beforeWindowStart: beforeWindowStart,
            beforeLoadedCount: beforeLoadedCount,
            reason: 'bottom-edge-no-newer-after-ready',
          );
        }
      } finally {
        _edgeNewerHistoryAccessInFlight = false;
        _rearmBottomEdgeAutoloadIfWindowUnchanged(
          beforeWindowStart: beforeWindowStart,
          beforeLoadedCount: beforeLoadedCount,
          reason: 'bottom-edge-no-progress',
        );
      }
    }());
  }

  void _rearmTopEdgeAutoloadIfWindowUnchanged({
    required int beforeWindowStart,
    required int beforeLoadedCount,
    required String reason,
  }) {
    if (_topEdgeAutoloadArmed) {
      return;
    }
    final windowUnchanged =
        _state._messageWindowStartIndex == beforeWindowStart &&
            _state._messages.length == beforeLoadedCount;
    if (!windowUnchanged) {
      return;
    }
    _topEdgeAutoloadArmed = true;
    Logger.debug(
      '[SessionEdgeDiag] top-edge rearmed session=${_state.widget.sessionId} '
      'reason=$reason ${_state._debugMessageWindowSummary()} '
      '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
    );
  }

  void _rearmBottomEdgeAutoloadIfWindowUnchanged({
    required int beforeWindowStart,
    required int beforeLoadedCount,
    required String reason,
  }) {
    if (_bottomEdgeAutoloadArmed) {
      return;
    }
    final windowUnchanged =
        _state._messageWindowStartIndex == beforeWindowStart &&
            _state._messages.length == beforeLoadedCount;
    if (!windowUnchanged) {
      return;
    }
    _bottomEdgeAutoloadArmed = true;
    Logger.debug(
      '[SessionEdgeDiag] bottom-edge rearmed session=${_state.widget.sessionId} '
      'reason=$reason ${_state._debugMessageWindowSummary()} '
      '${_state._debugScrollSummary()} ${debugEdgeLoadStateSummary()}',
    );
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
        ? _state._scrollController.effectivePosition
        : null;
    final trigger = position == null
        ? _SessionViewportController._historyEdgeLoadTrigger
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
    Logger.debug(
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
    Logger.debug(
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
    Logger.debug(
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
}
