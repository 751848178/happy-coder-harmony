part of 'session_screen.dart';

extension _SessionScreenStateTurns on _SessionScreenState {
  void _toggleAllTurns(List<_MessageTurnGroup> groups) {
    if (groups.isEmpty) {
      return;
    }
    _updateState(() {
      _collapseAllTurns = !_collapseAllTurns;
      _expandedTurnIds.clear();
      if (!_collapseAllTurns) {
        _expandedTurnIds.addAll(groups.map((group) => group.id));
      }
    });
    unawaited(_persistSessionUiState());
    _scheduleScrollToLatest(force: true);
  }

  void _toggleTurnGroup(_MessageTurnGroup group) {
    _updateState(() {
      if (_expandedTurnIds.contains(group.id)) {
        _expandedTurnIds.remove(group.id);
      } else {
        _expandedTurnIds.add(group.id);
      }
    });
    unawaited(_persistSessionUiState());
  }

  GlobalKey _turnSectionKey(String turnId) {
    return _turnSectionKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-section-$turnId'),
    );
  }

  GlobalKey _turnReplyAnchorKey(String turnId) {
    return _turnReplyAnchorKeys.putIfAbsent(
      turnId,
      () => GlobalKey(debugLabel: 'turn-reply-$turnId'),
    );
  }

  void _scheduleViewportStateRefresh() {
    if (_viewportUpdateScheduled) {
      return;
    }
    _viewportUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportUpdateScheduled = false;
      _refreshStickyTurnPrompt();
    });
  }


}
