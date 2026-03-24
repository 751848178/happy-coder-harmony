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
    List<session_models.Session> onlineSessions,
  ) async {
    for (final session in onlineSessions) {
      final existing = await _repository.getSession(session.id);
      final metadata = session.metadata == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(session.metadata!);
      if ((session.path ?? '').isNotEmpty) {
        metadata['path'] = session.path;
      }
      metadata[StorageService._localSessionSnapshotKey] = <String, dynamic>{
        'active': session.active,
        if (session.permissionMode != null)
          'permissionMode': session.permissionMode,
        if (session.modelMode != null) 'modelMode': session.modelMode,
        if (session.draft != null && session.draft!.trim().isNotEmpty)
          'draft': session.draft,
      };

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
