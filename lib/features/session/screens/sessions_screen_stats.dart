part of 'sessions_screen.dart';

extension SessionsScreenStats on _SessionsScreenState {
  Map<String, SessionStats> _resolveSessionStatsMap(
    List<Session> sessions,
    SessionServiceNotifier sessionNotifier,
  ) {
    final activeIds = sessions.map((session) => session.id).toSet();
    _sessionStatsCache
        .removeWhere((sessionId, _) => !activeIds.contains(sessionId));

    final statsBySessionId = <String, SessionStats>{};
    final pendingRequests = <SessionStatsSnapshotRequest>[];
    for (final session in sessions) {
      final messages = sessionNotifier.getSessionMessages(session.id)?.messages;
      final cached = _sessionStatsCache[session.id];
      if (cached != null && cached.matches(session, messages)) {
        statsBySessionId[session.id] = cached.stats;
        continue;
      }
      pendingRequests.add(
        SessionStatsSnapshotRequest(
          sessionId: session.id,
          session: session,
          messages: messages,
        ),
      );
      statsBySessionId[session.id] = SessionStatsCalculator.fromSessionPreview(
        session: session,
        messages: messages,
      );
    }
    _scheduleSessionStatsRefresh(pendingRequests, sessionNotifier);
    return statsBySessionId;
  }

  Map<String, bool> _resolveSessionThinkingMap(
    List<Session> sessions,
    SessionServiceNotifier sessionNotifier,
  ) {
    return {
      for (final session in sessions)
        session.id: sessionTurnIsThinkingStillBlocking(
          session: session,
          messages: sessionNotifier.getSessionMessages(session.id)?.messages ??
              const <ReducerMessage>[],
        ),
    };
  }

  void _scheduleSessionStatsRefresh(
    List<SessionStatsSnapshotRequest> requests,
    SessionServiceNotifier sessionNotifier,
  ) {
    final queuedRequests = requests
        .where((request) => !_sessionStatsInFlight.contains(request.sessionId))
        .toList(growable: false);
    if (queuedRequests.isEmpty) {
      return;
    }

    _sessionStatsInFlight
        .addAll(queuedRequests.map((request) => request.sessionId));
    unawaited(_refreshSessionStatsInBackground(
      queuedRequests,
      sessionNotifier,
    ));
  }

  Future<void> _refreshSessionStatsInBackground(
    List<SessionStatsSnapshotRequest> requests,
    SessionServiceNotifier sessionNotifier,
  ) async {
    try {
      final results = await computeSessionStatsBatch(requests);
      if (!mounted) {
        return;
      }

      var didUpdate = false;
      for (final request in requests) {
        final stats = results[request.sessionId];
        if (stats == null) {
          continue;
        }

        final currentSession = sessionNotifier.getSession(request.sessionId);
        final currentMessages =
            sessionNotifier.getSessionMessages(request.sessionId)?.messages;
        if (!identical(currentSession, request.session) ||
            !identical(currentMessages, request.messages)) {
          continue;
        }

        _sessionStatsCache[request.sessionId] = _SessionStatsCacheEntry(
          stats: stats,
          metadata: request.session.metadata,
          metadataVersion: request.session.metadataVersion,
          agentState: request.session.agentState,
          agentStateVersion: request.session.agentStateVersion,
          latestUsage: request.session.latestUsage,
          rawMessageCount: request.session.messages.length,
          messages: request.messages,
        );
        didUpdate = true;
      }

      if (didUpdate && mounted) {
        _rebuildView();
      }
    } finally {
      _sessionStatsInFlight
          .removeAll(requests.map((request) => request.sessionId));
    }
  }
}
