part of 'session_service.dart';

extension SessionServiceSessionUpdates on SessionServiceNotifier {
  void approveToolCall(String sessionId, String toolId) {
    _repository.approveToolCall(sessionId, toolId);
    Logger.info('Tool call approved: $toolId');
  }

  void rejectToolCall(String sessionId, String toolId, {String? reason}) {
    _repository.rejectToolCall(sessionId, toolId, reason: reason);
    Logger.info('Tool call rejected: $toolId');
  }

  Future<void> submitToolApproval({
    required String sessionId,
    required String toolId,
  }) async {
    approveToolCall(sessionId, toolId);
    final session = _repository.getSession(sessionId);
    final flavor = session?.metadata?['flavor']?.toString();
    await _submitPermissionDecision(
      sessionId: sessionId,
      request: {
        'id': toolId,
        'approved': true,
        if (flavor == 'codex') 'decision': 'approved',
      },
    );
    await loadSessionMessages(sessionId);
    unawaited(loadSessions(force: true));
  }

  Future<void> submitToolRejection({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    rejectToolCall(sessionId, toolId, reason: reason);
    final session = _repository.getSession(sessionId);
    final flavor = session?.metadata?['flavor']?.toString();
    await _submitPermissionDecision(
      sessionId: sessionId,
      request: {
        'id': toolId,
        'approved': false,
        if (flavor == 'codex') 'decision': 'abort',
      },
    );
    await loadSessionMessages(sessionId);
    unawaited(loadSessions(force: true));
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await ApiService.instance.delete<Map<String, dynamic>>(
        '/v1/sessions/$sessionId',
      );
    } catch (error) {
      if (!error.toString().contains('404')) {
        rethrow;
      }
    }
    await _purgeLocalSession(sessionId);
  }

  void clearSessionMessages(String sessionId) {
    _sessionLastSeq.remove(sessionId);
    _repository.clearSessionMessages(sessionId);
    unawaited(_persistSessionCacheImmediately(sessionId).catchError((
      Object error,
    ) {
      Logger.warning('Failed to persist cleared session cache: $error');
    }));
  }

  void updateDraft(String sessionId, String? draft) {
    _repository.updateSessionDraft(sessionId, draft);
  }

  void updatePermissionMode(String sessionId, String mode) {
    _repository.updateSessionPermissionMode(sessionId, mode);
    unawaited(_preferencesService
        .update(
      sessionId: sessionId,
      permissionMode: mode,
    )
        .catchError((Object error) {
      Logger.warning('Failed to persist permission mode: $error');
    }));
    unawaited(_syncSessionMetadata(
      sessionId: sessionId,
      permissionMode: mode,
    ).catchError((Object error) {
      Logger.warning('Failed to sync permission mode: $error');
    }));
  }

  void updateModelMode(String sessionId, String mode) {
    _repository.updateSessionModelMode(sessionId, mode);
    unawaited(_preferencesService
        .update(
      sessionId: sessionId,
      modelMode: mode,
    )
        .catchError((Object error) {
      Logger.warning('Failed to persist model mode: $error');
    }));
    unawaited(_syncSessionMetadata(
      sessionId: sessionId,
      modelMode: mode,
    ).catchError((Object error) {
      Logger.warning('Failed to sync model mode: $error');
    }));
  }

  Future<void> renameSession({
    required String sessionId,
    required String alias,
  }) async {
    final session = _repository.getSession(sessionId);
    if (session == null) {
      throw Exception('Session not found: $sessionId');
    }

    final normalizedAlias = _normalizeOptionalValue(alias);
    final fallbackMetadata = Map<String, dynamic>.from(
      session.metadata ?? const <String, dynamic>{},
    );
    if (normalizedAlias == null) {
      fallbackMetadata
        ..remove('name')
        ..remove('title');
    } else {
      fallbackMetadata['name'] = normalizedAlias;
      fallbackMetadata['title'] = normalizedAlias;
    }
    final nextTitle = normalizedAlias ??
        _resolveSessionTitle(
          path: session.path ?? fallbackMetadata['path']?.toString(),
          summary:
              _asStringMap(fallbackMetadata['summary'])?['text']?.toString(),
          name: fallbackMetadata['name']?.toString(),
          title: fallbackMetadata['title']?.toString(),
          fallback: session.title,
        );

    _repository.applySessions([
      session.copyWith(
        title: nextTitle,
        metadata: fallbackMetadata,
      ),
    ]);
    await _preferencesService.update(
        sessionId: sessionId, alias: normalizedAlias);

    try {
      await _syncSessionMetadata(sessionId: sessionId, alias: normalizedAlias);
    } catch (error) {
      Logger.warning('Failed to sync session alias to server: $error');
    }
    unawaited(loadSessions(force: true));
  }

  Future<void> _purgeLocalSession(String sessionId) async {
    _sessionDataKeys.remove(sessionId);
    _sessionLastSeq.remove(sessionId);
    await _composerQueueService.clearSession(sessionId);
    await _preferencesService.clearSession(sessionId);
    await _uiStateService.clearSession(sessionId);
    await StorageService.instance.deleteSession(sessionId);
    SocketRepository.instance.unsubscribeFromSession(sessionId);
    _repository.deleteSession(sessionId);
  }
}
