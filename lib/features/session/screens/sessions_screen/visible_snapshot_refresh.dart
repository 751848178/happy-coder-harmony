part of 'sessions_screen.dart';

extension _SessionListVisibleSnapshotRefresh on _SessionListRefreshController {
  Future<void> _refreshVisibleSessionSnapshotsInBackground({
    required bool force,
  }) async {
    final notifier = _state.ref.read(sessionStateProvider.notifier);
    final sessionIds = _sessionIdsForBackgroundRefresh(notifier);
    if (sessionIds.isEmpty) {
      return;
    }
    try {
      final priorityIds = sessionIds
          .take(_SessionListRefreshController._sessionListPriorityPreviewCount)
          .toList(growable: false);
      await notifier.refreshSessionMessageSnapshots(
        priorityIds,
        batchSize: force ? 4 : 6,
        force: force,
        maxPagesPerSession:
            _SessionListRefreshController._sessionListPreviewMaxPages,
      );

      final remainingIds = sessionIds
          .skip(_SessionListRefreshController._sessionListPriorityPreviewCount)
          .toList(growable: false);
      final tailIds = _nextTailSessionPreviewIds(remainingIds);
      if (tailIds.isNotEmpty) {
        await notifier.refreshSessionMessageSnapshots(
          tailIds,
          batchSize: force ? 3 : 2,
          force: force,
          maxPagesPerSession:
              _SessionListRefreshController._sessionListPreviewMaxPages,
        );
      }
    } catch (error) {
      Logger.warning('Failed to refresh visible session previews: $error');
    }
  }

  List<String> _sessionIdsForBackgroundRefresh(
    SessionServiceNotifier notifier,
  ) {
    final remoteSessions = notifier.sessions
        .where((session) => notifier.hasRemoteSession(session.id))
        .toList(growable: false)
      ..sort(compareSessionsByRecency);
    if (remoteSessions.isEmpty) {
      return const <String>[];
    }

    final settings = _state.ref.read(settingsStateProvider);
    final hideInactiveByDefault =
        _state.widget.showAppBar && settings.hideInactiveSessions;
    final visibleIds = remoteSessions
        .where(
          (session) => _state._matchesSessionFilters(
            session,
            selectedMachineId: _state.widget.selectedMachineId,
            hideInactiveByDefault: hideInactiveByDefault,
          ),
        )
        .map((session) => session.id)
        .toList(growable: false);
    final visibleSet = visibleIds.toSet();
    final remainingIds = remoteSessions
        .map((session) => session.id)
        .where((sessionId) => !visibleSet.contains(sessionId))
        .toList(growable: false);
    final activeDetailId = _activeSessionDetailId;
    final orderedIds = <String>[
      ...visibleIds,
      ...remainingIds,
    ];
    if (activeDetailId == null) {
      return orderedIds;
    }
    return orderedIds
        .where((sessionId) => sessionId != activeDetailId)
        .toList(growable: false);
  }

  List<String> _nextTailSessionPreviewIds(List<String> remainingIds) {
    if (remainingIds.isEmpty) {
      _sessionListTailRefreshCursor = 0;
      return const <String>[];
    }
    if (remainingIds.length <=
        _SessionListRefreshController._sessionListTailPreviewCount) {
      _sessionListTailRefreshCursor = 0;
      return remainingIds;
    }

    final normalizedCursor =
        _sessionListTailRefreshCursor % remainingIds.length;
    final selected = <String>[];
    for (var index = 0;
        index < _SessionListRefreshController._sessionListTailPreviewCount;
        index++) {
      final nextIndex = (normalizedCursor + index) % remainingIds.length;
      selected.add(remainingIds[nextIndex]);
    }
    _sessionListTailRefreshCursor =
        (normalizedCursor + selected.length) % remainingIds.length;
    return selected;
  }
}
