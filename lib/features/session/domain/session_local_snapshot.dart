import 'reducer.dart' show ReducerMessage;
import 'session_models.dart';

const String localSessionSnapshotMessageCountKey = 'messageCount';
const String localSessionSnapshotLatestUsageKey = 'latestUsage';
const String localSessionSnapshotMessagesLoadedKey = 'messagesLoaded';
const String localSessionSnapshotMessagesKey = 'messages';
const String localSessionSnapshotLastSeqKey = 'lastSeq';
const int localSessionSnapshotMessageWindowSize = 30;

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
    final snapshotMessages = _tailSnapshotMessages(
      loadedMessages,
      maxMessages: localSessionSnapshotMessageWindowSize,
    );
    snapshot[localSessionSnapshotMessagesLoadedKey] = true;
    snapshot[localSessionSnapshotMessagesKey] = snapshotMessages
            ?.map((message) => message.toJson())
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
  }
  if (lastSeq != null && lastSeq > 0) {
    snapshot[localSessionSnapshotLastSeqKey] = lastSeq;
  }

  // Pre-computed preview fields for session list — avoids loading all messages.
  if (session.previewText != null) {
    snapshot['previewText'] = session.previewText;
  }
  if (session.lastMessageAt != null) {
    snapshot['lastMessageAt'] = session.lastMessageAt!.toIso8601String();
  }
  if (session.listStatusKind != null) {
    snapshot['listStatusKind'] = session.listStatusKind;
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

  return restoreMessagesFromSnapshotPayload(rawMessages);
}

List<ReducerMessage> restoreMessagesFromSnapshotPayload(
  List<dynamic> rawMessages, {
  int? maxMessages,
}) {
  final sourceMessages =
      maxMessages != null && maxMessages > 0 && rawMessages.length > maxMessages
          ? rawMessages.sublist(rawMessages.length - maxMessages)
          : rawMessages;
  final restoredMessages = sourceMessages
      .map(_asStringMap)
      .whereType<Map<String, dynamic>>()
      .map(ReducerMessage.fromJson)
      .toList(growable: false);
  restoredMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return List<ReducerMessage>.unmodifiable(restoredMessages);
}

int? restoreSessionLastSeqFromLocalSnapshot(Map<String, dynamic>? localState) {
  return _parseOptionalInt(localState?[localSessionSnapshotLastSeqKey]);
}

int? restoreSessionMessageCountFromLocalSnapshot(
  Map<String, dynamic>? localState,
) {
  return _parseOptionalInt(localState?[localSessionSnapshotMessageCountKey]);
}

/// Restore pre-computed preview text from local snapshot.
String? restorePreviewTextFromLocalSnapshot(Map<String, dynamic>? localState) {
  final value = localState?['previewText'];
  if (value is String && value.isNotEmpty) return value;
  return null;
}

/// Restore pre-computed lastMessageAt from local snapshot.
DateTime? restoreLastMessageAtFromLocalSnapshot(
  Map<String, dynamic>? localState,
) {
  return _parseOptionalDateTime(localState?['lastMessageAt']);
}

/// Restore pre-computed listStatusKind from local snapshot.
String? restoreListStatusKindFromLocalSnapshot(
  Map<String, dynamic>? localState,
) {
  final value = localState?['listStatusKind'];
  if (value is String && value.isNotEmpty) return value;
  return null;
}

DateTime? _parseOptionalDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
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

List<ReducerMessage>? _tailSnapshotMessages(
  List<ReducerMessage>? messages, {
  required int maxMessages,
}) {
  if (messages == null || messages.length <= maxMessages) {
    return messages;
  }
  return List<ReducerMessage>.unmodifiable(
    messages.sublist(messages.length - maxMessages),
  );
}
