import 'reducer.dart' show ReducerMessage;
import 'session_models.dart';

const String localSessionSnapshotMessageCountKey = 'messageCount';
const String localSessionSnapshotLatestUsageKey = 'latestUsage';
const String localSessionSnapshotMessagesLoadedKey = 'messagesLoaded';
const String localSessionSnapshotMessagesKey = 'messages';
const String localSessionSnapshotLastSeqKey = 'lastSeq';

Map<String, dynamic> buildLocalSessionSnapshot({
  required Session session,
  int? loadedMessageCount,
  List<ReducerMessage>? loadedMessages,
  bool messagesLoaded = false,
  int? lastSeq,
}) {
  final snapshot = <String, dynamic>{
    'active': session.active,
    if (session.permissionMode != null)
      'permissionMode': session.permissionMode,
    if (session.modelMode != null) 'modelMode': session.modelMode,
    if (session.draft != null && session.draft!.trim().isNotEmpty)
      'draft': session.draft,
  };

  final messageCount = resolvePersistedSessionMessageCount(
    session: session,
    loadedMessageCount: loadedMessageCount,
  );
  if (messageCount != null) {
    snapshot[localSessionSnapshotMessageCountKey] = messageCount;
  }

  final latestUsage = resolvePersistedSessionLatestUsage(
    session: session,
    loadedMessageCount: loadedMessageCount,
  );
  if (latestUsage != null) {
    snapshot[localSessionSnapshotLatestUsageKey] = latestUsage.toJson();
  }

  if (messagesLoaded) {
    snapshot[localSessionSnapshotMessagesLoadedKey] = true;
    snapshot[localSessionSnapshotMessagesKey] = loadedMessages
            ?.map((message) => message.toJson())
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
  }
  if (lastSeq != null && lastSeq > 0) {
    snapshot[localSessionSnapshotLastSeqKey] = lastSeq;
  }

  return snapshot;
}

int? resolvePersistedSessionMessageCount({
  required Session session,
  int? loadedMessageCount,
}) {
  if (loadedMessageCount != null) {
    return loadedMessageCount;
  }
  return _firstPositive([
    session.latestUsage?.messageCount,
    _deepInt(session.metadata, const ['summary', 'messageCount']),
    _deepInt(session.metadata, const ['stats', 'messageCount']),
    _deepInt(session.metadata, const ['messageCount']),
    _deepInt(session.agentState, const ['messageCount']),
    _deepInt(session.agentState, const ['summary', 'messageCount']),
    _deepInt(session.agentState, const ['stats', 'messageCount']),
    session.messages.isNotEmpty ? session.messages.length : null,
  ]);
}

LatestUsage? resolvePersistedSessionLatestUsage({
  required Session session,
  int? loadedMessageCount,
}) {
  final messageCount = resolvePersistedSessionMessageCount(
    session: session,
    loadedMessageCount: loadedMessageCount,
  );
  final existing = session.latestUsage;
  if (existing != null) {
    if (messageCount == null || existing.messageCount == messageCount) {
      return existing;
    }
    return LatestUsage(
      messageCount: messageCount,
      tokenCount: existing.tokenCount,
      timestamp: existing.timestamp,
      filesAccessed: existing.filesAccessed,
      toolsUsed: existing.toolsUsed,
    );
  }
  if (messageCount == null) {
    return null;
  }
  return LatestUsage(
    messageCount: messageCount,
    tokenCount: 0,
    timestamp: session.updatedAt,
  );
}

LatestUsage? restoreLatestUsageFromLocalSnapshot(
  Map<String, dynamic>? localState, {
  required DateTime fallbackTimestamp,
}) {
  final latestUsageJson =
      _asStringMap(localState?[localSessionSnapshotLatestUsageKey]);
  if (latestUsageJson != null) {
    return LatestUsage.fromJson(latestUsageJson);
  }

  final messageCount =
      _parseOptionalInt(localState?[localSessionSnapshotMessageCountKey]);
  if (messageCount == null) {
    return null;
  }

  return LatestUsage(
    messageCount: messageCount,
    tokenCount: 0,
    timestamp: fallbackTimestamp,
  );
}

bool localSnapshotHasLoadedMessages(Map<String, dynamic>? localState) {
  return localState?[localSessionSnapshotMessagesLoadedKey] == true;
}

List<ReducerMessage>? restoreMessagesFromLocalSnapshot(
  Map<String, dynamic>? localState,
) {
  if (!localSnapshotHasLoadedMessages(localState)) {
    return null;
  }

  final rawMessages = localState?[localSessionSnapshotMessagesKey];
  if (rawMessages is! List) {
    return const <ReducerMessage>[];
  }

  return rawMessages
      .map(_asStringMap)
      .whereType<Map<String, dynamic>>()
      .map(ReducerMessage.fromJson)
      .toList(growable: false)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

int? restoreSessionLastSeqFromLocalSnapshot(Map<String, dynamic>? localState) {
  return _parseOptionalInt(localState?[localSessionSnapshotLastSeqKey]);
}

int resolveDisplaySessionMessageCount({
  required Session session,
  int? loadedMessageCount,
}) {
  if (loadedMessageCount == null) {
    return resolvePersistedSessionMessageCount(session: session) ?? 0;
  }
  return loadedMessageCount;
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return null;
}

int? _deepInt(Map<String, dynamic>? source, List<String> path) {
  dynamic current = source;
  for (final segment in path) {
    if (current is! Map) {
      return null;
    }
    current = current[segment];
  }
  return _parseOptionalInt(current);
}

int? _parseOptionalInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

int? _firstPositive(Iterable<int?> values) {
  for (final value in values) {
    if (value != null && value > 0) {
      return value;
    }
  }
  return null;
}
