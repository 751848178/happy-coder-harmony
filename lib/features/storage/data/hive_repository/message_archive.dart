part of 'hive_repository.dart';

int? parseSessionMessageArchiveIndexFromKey(
  String key, {
  required String prefix,
}) {
  if (!key.startsWith(prefix)) {
    return null;
  }
  final suffix = key.substring(prefix.length);
  if (suffix.isEmpty) {
    return null;
  }
  final match = RegExp(r'^(\d+)').firstMatch(suffix);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

extension HiveRepositoryMessageArchive on HiveRepository {
  static const String _sessionMessageArchiveKeySeparator = '::archive::';
  static const String _sessionMessageArchiveSummaryKey =
      '__happySessionMessageArchiveSummary';

  Future<void> clearSessionMessageArchive(String sessionId) async {
    final keys = _sessionMessageArchiveKeys(sessionId);
    if (keys.isEmpty) {
      await _writeSessionMessageArchiveSummary(
        sessionId,
        const SessionMessageArchiveSummary(),
      );
      return;
    }
    await _messagesBox.deleteAll(keys);
    await _writeSessionMessageArchiveSummary(
      sessionId,
      const SessionMessageArchiveSummary(),
    );
    _statsController.add(await _computeStats());
  }

  Future<void> appendSessionMessageArchiveChunk(
    String sessionId,
    List<MessageStorageModel> records, {
    required int startIndex,
  }) async {
    if (records.isEmpty) {
      return;
    }
    final entries = <String, MessageStorageModel>{};
    for (var index = 0; index < records.length; index++) {
      final archiveIndex = startIndex + index;
      entries[_sessionMessageArchiveKey(
        sessionId,
        archiveIndex: archiveIndex,
      )] = records[index];
    }
    await _messagesBox.putAll(entries);
  }

  Future<int> getSessionMessageArchiveCount(String sessionId) async {
    return (await getSessionMessageArchiveSummary(sessionId)).messageCount;
  }

  Future<SessionMessageArchiveSummary> getSessionMessageArchiveSummary(
    String sessionId,
  ) async {
    final session = _sessionsBox.get(sessionId);
    final rawSummary = session?.metadata?[_sessionMessageArchiveSummaryKey];
    if (rawSummary is! Map) {
      final fallback = _computeSessionMessageArchiveSummaryFromKeys(sessionId);
      if (fallback.messageCount > 0) {
        await _writeSessionMessageArchiveSummary(sessionId, fallback);
      }
      return fallback;
    }
    final normalized = rawSummary.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final countValue = normalized['messageCount'];
    final completeValue = normalized['isComplete'];
    final lastRemoteSeqValue = normalized['lastRemoteSeq'];
    final messageCount = countValue is num
        ? countValue.toInt()
        : int.tryParse(countValue?.toString() ?? '') ?? 0;
    final lastRemoteSeq = lastRemoteSeqValue is num
        ? lastRemoteSeqValue.toInt()
        : int.tryParse(lastRemoteSeqValue?.toString() ?? '') ?? 0;
    final parsed = SessionMessageArchiveSummary(
      messageCount: messageCount < 0 ? 0 : messageCount,
      isComplete: completeValue == true,
      lastRemoteSeq: lastRemoteSeq < 0 ? 0 : lastRemoteSeq,
    );
    if (parsed.messageCount > 0) {
      return parsed;
    }
    final fallback = _computeSessionMessageArchiveSummaryFromKeys(sessionId);
    if (fallback.messageCount > 0) {
      await _writeSessionMessageArchiveSummary(sessionId, fallback);
      return fallback;
    }
    return parsed;
  }

  Future<void> saveSessionMessageArchiveSummary(
    String sessionId,
    SessionMessageArchiveSummary summary,
  ) async {
    await _writeSessionMessageArchiveSummary(sessionId, summary);
    _statsController.add(await _computeStats());
  }

  Future<List<MessageStorageModel>> loadSessionMessageArchiveRange(
    String sessionId, {
    required int startIndex,
    required int limit,
  }) async {
    if (limit <= 0) {
      return const <MessageStorageModel>[];
    }
    final summary = await getSessionMessageArchiveSummary(sessionId);
    final archiveCount = summary.messageCount;
    if (archiveCount <= 0 || startIndex >= archiveCount) {
      return const <MessageStorageModel>[];
    }
    final endIndex =
        (startIndex + limit) > archiveCount ? archiveCount : startIndex + limit;
    final records = <MessageStorageModel>[];
    var directLookupMissed = false;
    for (var archiveIndex = startIndex;
        archiveIndex < endIndex;
        archiveIndex++) {
      final key = _sessionMessageArchiveKey(
        sessionId,
        archiveIndex: archiveIndex,
      );
      final record = _messagesBox.get(key);
      if (record != null) {
        records.add(record);
      } else {
        directLookupMissed = true;
        break;
      }
    }
    if (!directLookupMissed) {
      return records;
    }
    final fallbackRecords = _loadSessionMessageArchiveRangeFromPrefixScan(
      sessionId,
      startIndex: startIndex,
      endIndex: endIndex,
    );
    if (fallbackRecords.isNotEmpty) {
      Logger.warning(
        'Fell back to prefix-scanned archive window for session: $sessionId '
        '(start=$startIndex, end=$endIndex, direct=${records.length}, '
        'fallback=${fallbackRecords.length})',
      );
      return fallbackRecords;
    }
    return records;
  }

  List<String> _sessionMessageArchiveKeys(String sessionId) {
    final prefix = '$sessionId$_sessionMessageArchiveKeySeparator';
    return _messagesBox.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false)
      ..sort();
  }

  String _sessionMessageArchiveKey(
    String sessionId, {
    required int archiveIndex,
  }) {
    final indexText = archiveIndex.toString().padLeft(10, '0');
    return '$sessionId$_sessionMessageArchiveKeySeparator$indexText';
  }

  SessionMessageArchiveSummary _computeSessionMessageArchiveSummaryFromKeys(
    String sessionId,
  ) {
    final orderedKeys = _sessionMessageArchiveIndexedKeys(sessionId);
    if (orderedKeys.isEmpty) {
      return const SessionMessageArchiveSummary();
    }
    final indexes = orderedKeys.keys.toList(growable: false)..sort();
    final firstIndex = indexes.first;
    final lastIndex = indexes.last;
    final contiguous = firstIndex == 0 && indexes.length == lastIndex + 1;
    return SessionMessageArchiveSummary(
      messageCount: lastIndex + 1,
      isComplete: contiguous,
      lastRemoteSeq: 0,
    );
  }

  List<MessageStorageModel> _loadSessionMessageArchiveRangeFromPrefixScan(
    String sessionId, {
    required int startIndex,
    required int endIndex,
  }) {
    final indexedKeys = _sessionMessageArchiveIndexedKeys(sessionId);
    if (indexedKeys.isEmpty) {
      return const <MessageStorageModel>[];
    }
    final records = <MessageStorageModel>[];
    for (var archiveIndex = startIndex;
        archiveIndex < endIndex;
        archiveIndex++) {
      final key = indexedKeys[archiveIndex];
      if (key == null) {
        continue;
      }
      final record = _messagesBox.get(key);
      if (record != null) {
        records.add(record);
      }
    }
    return records;
  }

  Map<int, String> _sessionMessageArchiveIndexedKeys(String sessionId) {
    final prefix = '$sessionId$_sessionMessageArchiveKeySeparator';
    final indexedKeys = <int, String>{};
    for (final key in _messagesBox.keys.whereType<String>()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final archiveIndex = parseSessionMessageArchiveIndexFromKey(
        key,
        prefix: prefix,
      );
      if (archiveIndex == null) {
        continue;
      }
      final existingKey = indexedKeys[archiveIndex];
      if (existingKey == null ||
          key ==
              _sessionMessageArchiveKey(
                sessionId,
                archiveIndex: archiveIndex,
              )) {
        indexedKeys[archiveIndex] = key;
      }
    }
    return indexedKeys;
  }

  Future<void> _writeSessionMessageArchiveSummary(
    String sessionId,
    SessionMessageArchiveSummary summary,
  ) async {
    final session = _sessionsBox.get(sessionId);
    if (session == null) {
      return;
    }
    final nextMetadata = session.metadata == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(session.metadata!);
    nextMetadata[_sessionMessageArchiveSummaryKey] = <String, dynamic>{
      'messageCount': summary.messageCount,
      'isComplete': summary.isComplete,
      'lastRemoteSeq': summary.lastRemoteSeq,
    };
    await _sessionsBox.put(
      sessionId,
      _copySession(
        session,
        metadata: nextMetadata,
      ),
    );
  }
}
