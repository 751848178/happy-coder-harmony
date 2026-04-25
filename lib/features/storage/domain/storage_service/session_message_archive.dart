part of 'storage_service.dart';

extension StorageSessionMessageArchive on StorageService {
  static const int _archivedTurnSummaryBatchSize = 240;

  Future<void> clearSessionMessageArchive(String sessionId) {
    return _repository.clearSessionMessageArchive(sessionId);
  }

  Future<void> appendSessionMessageArchiveChunk(
    String sessionId,
    List<ReducerMessage> messages, {
    required int startIndex,
  }) async {
    if (messages.isEmpty) {
      return;
    }
    final records = <MessageStorageModel>[
      for (var index = 0; index < messages.length; index++)
        _messageArchiveRecord(
          sessionId: sessionId,
          message: messages[index],
          archiveIndex: startIndex + index,
        ),
    ];
    await _repository.appendSessionMessageArchiveChunk(
      sessionId,
      records,
      startIndex: startIndex,
    );
  }

  Future<int> getSessionMessageArchiveCount(String sessionId) {
    return _repository.getSessionMessageArchiveCount(sessionId);
  }

  Future<SessionMessageArchiveSummary> getSessionMessageArchiveSummary(
    String sessionId,
  ) {
    return _repository.getSessionMessageArchiveSummary(sessionId);
  }

  Future<void> saveSessionMessageArchiveSummary(
    String sessionId, {
    required int messageCount,
    required bool isComplete,
    int lastRemoteSeq = 0,
  }) {
    return _repository.saveSessionMessageArchiveSummary(
      sessionId,
      SessionMessageArchiveSummary(
        messageCount: messageCount,
        isComplete: isComplete,
        lastRemoteSeq: lastRemoteSeq,
      ),
    );
  }

  Future<List<ReducerMessage>> loadSessionMessageArchiveRange(
    String sessionId, {
    required int startIndex,
    required int limit,
  }) async {
    final records = await _repository.loadSessionMessageArchiveRange(
      sessionId,
      startIndex: startIndex,
      limit: limit,
    );
    final restored = <ReducerMessage>[];
    for (final record in records) {
      try {
        final raw = jsonDecode(record.content);
        if (raw is! Map) {
          continue;
        }
        final json = raw.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        restored.add(ReducerMessage.fromJson(json));
      } catch (error) {
        Logger.warning(
          'Failed to decode archived session message '
          '(session=$sessionId, message=${record.id}): $error',
        );
      }
    }
    restored.sort((a, b) {
      final aArchiveIndex = _archivedReducerMessageIndex(a);
      final bArchiveIndex = _archivedReducerMessageIndex(b);
      if (aArchiveIndex != null && bArchiveIndex != null) {
        return aArchiveIndex.compareTo(bArchiveIndex);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return List<ReducerMessage>.unmodifiable(restored);
  }

  Future<List<SessionArchivedTurnSummary>> loadSessionArchivedTurnSummaries(
    String sessionId,
  ) async {
    final summary = await getSessionMessageArchiveSummary(sessionId);
    if (summary.messageCount <= 0) {
      return const <SessionArchivedTurnSummary>[];
    }
    final summaries = <SessionArchivedTurnSummary>[];
    for (var startIndex = 0;
        startIndex < summary.messageCount;
        startIndex += _archivedTurnSummaryBatchSize) {
      final records = await _repository.loadSessionMessageArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: _archivedTurnSummaryBatchSize,
      );
      for (final record in records) {
        final parsed = _tryParseArchivedTurnSummary(record);
        if (parsed != null) {
          summaries.add(parsed);
        }
      }
    }
    return List<SessionArchivedTurnSummary>.unmodifiable(summaries);
  }
}

int? _archivedReducerMessageIndex(ReducerMessage message) {
  final rawValue = message.metadata?['archiveIndex'];
  if (rawValue is int) {
    return rawValue;
  }
  if (rawValue is String) {
    return int.tryParse(rawValue);
  }
  if (rawValue is double) {
    return rawValue.toInt();
  }
  return null;
}

MessageStorageModel _messageArchiveRecord({
  required String sessionId,
  required ReducerMessage message,
  required int archiveIndex,
}) {
  final metadata = message.metadata == null
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(message.metadata!);
  metadata['archiveIndex'] = archiveIndex;
  return MessageStorageModel(
    id: message.id,
    sessionId: sessionId,
    content: jsonEncode(message.copyWith(metadata: metadata).toJson()),
    role: metadata['role']?.toString() ?? message.kind,
    createdAt: message.createdAt,
    metadata: <String, dynamic>{
      'archiveIndex': archiveIndex,
      'kind': message.kind,
    },
  );
}

SessionArchivedTurnSummary? _tryParseArchivedTurnSummary(
  MessageStorageModel record,
) {
  final archiveIndex = _storageArchiveIndex(record);
  if (archiveIndex == null) {
    return null;
  }
  try {
    final raw = jsonDecode(record.content);
    if (raw is! Map) {
      return null;
    }
    final json = raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final kind = json['kind']?.toString() ?? 'text';
    if (kind != 'text') {
      return null;
    }
    final metadata = _normalizeArchivedMessageMetadata(json['metadata']);
    final role = metadata?['role']?.toString();
    final sourceRole = metadata?['sourceRole']?.toString();
    if (role != 'user' && sourceRole != 'user') {
      return null;
    }
    final text = (json['text']?.toString() ?? '').trim();
    final createdAt =
        _storageArchivedMessageCreatedAt(json) ?? record.createdAt;
    final promptMessageId = json['id']?.toString() ?? record.id;
    return SessionArchivedTurnSummary(
      id: promptMessageId,
      promptMessageId: promptMessageId,
      preview: _archivedTurnSummaryPreview(text),
      createdAt: createdAt,
      archiveIndex: archiveIndex,
    );
  } catch (error) {
    Logger.warning(
      'Failed to decode archived turn summary '
      '(session=${record.sessionId}, message=${record.id}): $error',
    );
    return null;
  }
}

Map<String, dynamic>? _normalizeArchivedMessageMetadata(dynamic value) {
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

DateTime? _storageArchivedMessageCreatedAt(Map<String, dynamic> json) {
  final value = json['createdAt'];
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    if (value.isEmpty) {
      return null;
    }
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}

int? _storageArchiveIndex(MessageStorageModel record) {
  final rawValue = record.metadata?['archiveIndex'];
  if (rawValue is int) {
    return rawValue;
  }
  if (rawValue is String) {
    return int.tryParse(rawValue);
  }
  if (rawValue is double) {
    return rawValue.toInt();
  }
  return null;
}

String _archivedTurnSummaryPreview(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return '空消息';
  }
  final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= 56) {
    return normalized;
  }
  return '${normalized.substring(0, 56)}...';
}
