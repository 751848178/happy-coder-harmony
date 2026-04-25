part of '../session_detail.dart';

extension _SessionScreenBodyMetricsPresenter on _SessionScreenBodyPresenter {
  SessionStats? resolveSessionStats(
    Session? session,
    List<ReducerMessage> messages,
  ) {
    if (session == null) {
      return null;
    }
    if (identical(_cachedStatsSession, session) &&
        identical(_cachedStatsMessages, messages)) {
      return _cachedSessionStats;
    }
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: messages,
    );
    _cachedStatsSession = session;
    _cachedStatsMessages = messages;
    _cachedSessionStats = stats;
    return stats;
  }

  SessionThinkingSnapshot resolveThinkingSnapshot(
    Session session,
    List<ReducerMessage> messages,
  ) {
    if (!identical(_cachedThinkingSession, session) ||
        !identical(_cachedThinkingMessages, messages)) {
      _cachedThinkingSession = session;
      _cachedThinkingMessages = messages;
      _cachedThinkingSnapshot = resolveSessionThinkingSnapshot(
        session: session,
        messages: messages,
      );
    }
    return _cachedThinkingSnapshot;
  }
}
