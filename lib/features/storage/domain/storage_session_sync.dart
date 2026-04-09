part of 'storage_service.dart';

extension StorageSessionSync on StorageService {
  /// 同步在线数据到本地
  Future<void> syncFromOnline(List<Session> onlineSessions) async {
    for (final session in onlineSessions) {
      final existing = await _repository.getSession(session.id);

      if (existing == null) {
        final storageModel = SessionStorageModel(
          id: session.id,
          title: session.title,
          messages:
              session.messages.map((message) => message.toString()).toList(),
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
          lastAccessedAt: DateTime.now(),
          isPinned: false,
          isArchived: false,
          tag: session.tag,
          metadata: session.metadata,
        );
        await _repository.saveSession(storageModel);
      } else {
        await _repository.updateSessionAccessTime(session.id);
      }
    }
  }

  /// 缓存远端会话摘要，供启动时快速恢复列表
  Future<void> cacheRemoteSessions(
    List<session_models.Session> onlineSessions, {
    Map<String, Map<String, dynamic>> localStateBySessionId = const {},
  }) async {
    for (final session in onlineSessions) {
      final existing = await _repository.getSession(session.id);
      final metadata = session.metadata == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(session.metadata!);
      if ((session.path ?? '').isNotEmpty) {
        metadata['path'] = session.path;
      }

      final newSnapshot = localStateBySessionId[session.id] ??
          buildLocalSessionSnapshot(session: session);

      // Preserve existing cached message data when the new snapshot has none.
      // Bulk persists are triggered by session metadata changes and may not
      // have message data for every session.  Without this guard, they would
      // overwrite per-session message cache with empty snapshots.
      final existingSnapshot =
          existing?.metadata?[StorageService._localSessionSnapshotKey];
      if (existingSnapshot is Map &&
          !newSnapshot.containsKey('messagesLoaded') &&
          existingSnapshot.containsKey('messagesLoaded')) {
        final merged = Map<String, dynamic>.from(newSnapshot);
        for (final key in const [
          'messagesLoaded',
          'messages',
          'lastSeq',
          'messageCount',
        ]) {
          if (existingSnapshot.containsKey(key)) {
            merged[key] = existingSnapshot[key];
          }
        }
        metadata[StorageService._localSessionSnapshotKey] = merged;
      } else {
        metadata[StorageService._localSessionSnapshotKey] = newSnapshot;
      }

      final storageModel = SessionStorageModel(
        id: session.id,
        title: session.title,
        messages: existing?.messages ?? const [],
        createdAt: session.createdAt,
        updatedAt: session.updatedAt,
        lastAccessedAt: existing?.lastAccessedAt ?? session.updatedAt,
        isPinned: existing?.isPinned ?? false,
        isArchived: existing?.isArchived ?? !session.active,
        tag: session.tag,
        metadata: metadata.isEmpty ? null : metadata,
      );
      await _repository.saveSession(storageModel);
    }
  }
}
