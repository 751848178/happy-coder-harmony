import 'session_models.dart';

int compareSessionsByRecency(Session a, Session b) {
  final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
  if (byUpdatedAt != 0) {
    return byUpdatedAt;
  }

  final byCreatedAt = b.createdAt.compareTo(a.createdAt);
  if (byCreatedAt != 0) {
    return byCreatedAt;
  }

  final bySeq = (b.seq ?? -1).compareTo(a.seq ?? -1);
  if (bySeq != 0) {
    return bySeq;
  }

  return a.id.compareTo(b.id);
}

int compareSessionsByStableListOrder(Session a, Session b) {
  final byCreatedAt = b.createdAt.compareTo(a.createdAt);
  if (byCreatedAt != 0) {
    return byCreatedAt;
  }

  final bySeq = (b.seq ?? -1).compareTo(a.seq ?? -1);
  if (bySeq != 0) {
    return bySeq;
  }

  final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
  if (byUpdatedAt != 0) {
    return byUpdatedAt;
  }

  return a.id.compareTo(b.id);
}

List<Session> orderSessionsByStoredIds(
  Iterable<String> orderedIds,
  Map<String, Session> sessionMap,
) {
  final sessions = <Session>[];
  final seen = <String>{};
  for (final sessionId in orderedIds) {
    final session = sessionMap[sessionId];
    if (session == null || !seen.add(session.id)) {
      continue;
    }
    sessions.add(session);
  }
  return sessions;
}

DateTime resolveSessionUpdatedAtForRealtimeUpdate({
  required DateTime currentUpdatedAt,
  DateTime? sessionUpdatedAt,
  DateTime? eventCreatedAt,
}) {
  final candidate = sessionUpdatedAt ?? eventCreatedAt;
  if (candidate == null || candidate.isBefore(currentUpdatedAt)) {
    return currentUpdatedAt;
  }
  return candidate;
}
