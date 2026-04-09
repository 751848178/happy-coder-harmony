part of 'session_service.dart';

class _SessionServiceCacheCoordinator {
  const _SessionServiceCacheCoordinator(this._notifier);

  final SessionServiceNotifier _notifier;

  Future<_CachedSessionRestoreResult> restoreCachedSessions() async {
    try {
      final cachedSessions = await StorageService.instance.getAllSessions();
      final restoredSessions = <Session>[];
      final restoredLastSeqs = <String, int>{};

      for (final cached in cachedSessions) {
        final localState = extractLocalSessionStateFromMetadata(cached.metadata);
        final session = sessionFromCache(cached, localState: localState);
        restoredSessions.add(session);
        final lastSeq = restoreSessionLastSeqFromLocalSnapshot(localState);
        if (lastSeq != null && lastSeq > 0) {
          restoredLastSeqs[session.id] = lastSeq;
        }
      }

      restoredSessions.sort(compareSessionsByRecency);
      return _CachedSessionRestoreResult(
        sessions: restoredSessions,
        sessionMessagesById: const {},
        lastSeqBySessionId: restoredLastSeqs,
      );
    } catch (error) {
      Logger.warning('Failed to restore cached sessions: $error');
      return const _CachedSessionRestoreResult();
    }
  }

  Session sessionFromCache(
    storage_models.SessionStorageModel cached, {
    Map<String, dynamic>? localState,
  }) {
    final metadata = cached.metadata == null
        ? null
        : Map<String, dynamic>.from(cached.metadata!);
    metadata?.remove(SessionServiceNotifier._localSessionSnapshotKey);
    return Session(
      id: cached.id,
      title: cached.title,
      messages: const [],
      createdAt: cached.createdAt,
      updatedAt: cached.updatedAt,
      active: localState?['active'] as bool? ?? !cached.isArchived,
      tag: cached.tag,
      path: metadata?['path']?.toString(),
      metadata: metadata,
      latestUsage: restoreLatestUsageFromLocalSnapshot(
        localState,
        fallbackTimestamp: cached.updatedAt,
      ),
      permissionMode: resolveSessionPermissionMode(
        metadata: metadata,
        persistedValue: localState?['permissionMode']?.toString(),
        metadataValue: metadata?['currentOperatingModeCode']?.toString(),
      ),
      modelMode: resolveSessionModelMode(
        metadata: metadata,
        persistedValue: localState?['modelMode']?.toString(),
        metadataValue: metadata?['currentModelCode']?.toString(),
        fallbackAgent: metadata?['flavor']?.toString(),
      ),
      draft: _notifier._normalizeOptionalValue(localState?['draft']?.toString()),
      previewText: restorePreviewTextFromLocalSnapshot(localState),
      lastMessageAt: restoreLastMessageAtFromLocalSnapshot(localState),
      listStatusKind: restoreListStatusKindFromLocalSnapshot(localState),
    );
  }

  Map<String, dynamic>? extractLocalSessionStateFromMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) {
      return null;
    }
    return _notifier
        ._asStringMap(metadata[SessionServiceNotifier._localSessionSnapshotKey]);
  }

  Future<void> persistCachedSessions(
    List<Session> sessions, {
    Map<String, SessionMessages> sessionMessagesById = const {},
  }) async {
    try {
      final localStateBySessionId = <String, Map<String, dynamic>>{};
      for (final session in sessions) {
        final cachedMessages = sessionMessagesById[session.id];
        final canPersistLoadedWindow = cachedMessages?.isLoaded == true &&
            cachedMessages?.hasNewerMessages != true;
        localStateBySessionId[session.id] = buildLocalSessionSnapshot(
          session: session,
          loadedMessageCount: canPersistLoadedWindow
              ? cachedMessages!.totalMessageCount
              : null,
          loadedMessages:
              canPersistLoadedWindow ? cachedMessages!.messages : null,
          messagesLoaded: canPersistLoadedWindow,
          lastSeq: _notifier._sessionLastSeq[session.id],
        );
      }
      await StorageService.instance.cacheRemoteSessions(
        sessions,
        localStateBySessionId: localStateBySessionId,
      );
    } catch (error) {
      Logger.warning('Failed to persist cached sessions: $error');
    }
  }

  Future<void> persistSessionCacheImmediately(String sessionId) async {
    final session = _notifier._repository.getSession(sessionId);
    if (session == null) {
      await StorageService.instance.deleteSession(sessionId);
      return;
    }
    final sessionMessages = _notifier._repository.getSessionMessages(sessionId);
    await persistCachedSessions(
      [session],
      sessionMessagesById: sessionMessages == null
          ? const <String, SessionMessages>{}
          : <String, SessionMessages>{sessionId: sessionMessages},
    );
  }

  Future<bool> restoreSessionMessagesFromCache(String sessionId) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing?.isLoaded == true) {
      return true;
    }

    try {
      final cached = await StorageService.instance.getSession(sessionId);
      if (cached == null) {
        return false;
      }

      final localState = extractLocalSessionStateFromMetadata(cached.metadata);
      if (!localSnapshotHasLoadedMessages(localState)) {
        return false;
      }

      final rawMessages = localState?[localSessionSnapshotMessagesKey];
      if (rawMessages is! List) {
        return false;
      }
      final totalMessageCount =
          restoreSessionMessageCountFromLocalSnapshot(localState) ??
              rawMessages.length;
      final messages =
          rawMessages.length >= _SessionServiceMessageCoordinator
              .sessionCacheParseIsolateThreshold
          ? await compute(
              restoreMessagesFromSnapshotPayload,
              List<dynamic>.from(
                rawMessages.length >
                        SessionServiceNotifier
                            .sessionDetailAutomaticMessageWindowSize
                    ? rawMessages.sublist(
                        rawMessages.length -
                            SessionServiceNotifier
                                .sessionDetailAutomaticMessageWindowSize,
                      )
                    : rawMessages,
                growable: false,
              ),
            )
          : restoreMessagesFromSnapshotPayload(
              rawMessages,
              maxMessages:
                  SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
            );

      _notifier._repository.replaceMessages(
        sessionId,
        messages,
        preserveOptimisticMessages: false,
        totalMessageCount: totalMessageCount,
      );

      final lastSeq = restoreSessionLastSeqFromLocalSnapshot(localState);
      if (lastSeq != null && lastSeq > 0) {
        _notifier._sessionLastSeq[sessionId] = lastSeq;
      }
      Logger.info(
        'Restored ${messages.length}/$totalMessageCount session messages '
        'from cache: $sessionId',
      );
      return true;
    } catch (error) {
      Logger.warning(
        'Failed to restore session messages from cache for $sessionId: $error',
      );
      return false;
    }
  }
}
