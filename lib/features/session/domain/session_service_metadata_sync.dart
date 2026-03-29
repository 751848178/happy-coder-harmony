part of 'session_service.dart';

extension SessionServiceMetadataSync on SessionServiceNotifier {
  Future<String> _encryptSessionMessage({
    required String sessionId,
    required Map<String, dynamic> rawRecord,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(rawRecord, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(rawRecord, secretKey);
    }
    throw Exception('Missing session encryption key');
  }

  Future<String> _encodeSessionMetadataPayload({
    required String sessionId,
    required Map<String, dynamic> metadata,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(metadata, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(metadata, secretKey);
    }
    return jsonEncode(metadata);
  }

  Future<void> _syncSessionMetadata({
    required String sessionId,
    Object? alias = SessionServiceNotifier._sessionOverrideSentinel,
    Object? permissionMode = SessionServiceNotifier._sessionOverrideSentinel,
    Object? modelMode = SessionServiceNotifier._sessionOverrideSentinel,
  }) async {
    final session = _repository.getSession(sessionId);
    if (session == null) {
      return;
    }

    final nextMetadata = Map<String, dynamic>.from(
      session.metadata ?? const <String, dynamic>{},
    );
    if (!identical(alias, SessionServiceNotifier._sessionOverrideSentinel)) {
      final normalizedAlias = _normalizeOptionalValue(alias as String?);
      if (normalizedAlias == null) {
        nextMetadata
          ..remove('name')
          ..remove('title');
      } else {
        nextMetadata['name'] = normalizedAlias;
        nextMetadata['title'] = normalizedAlias;
      }
    }

    if (!identical(
      permissionMode,
      SessionServiceNotifier._sessionOverrideSentinel,
    )) {
      final normalizedPermissionMode =
          _normalizeOptionalValue(permissionMode as String?);
      if (normalizedPermissionMode == null) {
        nextMetadata.remove('currentOperatingModeCode');
      } else {
        nextMetadata['currentOperatingModeCode'] = normalizedPermissionMode;
      }
    }

    if (!identical(
        modelMode, SessionServiceNotifier._sessionOverrideSentinel)) {
      final normalizedModelMode = _normalizeOptionalValue(modelMode as String?);
      if (normalizedModelMode == null) {
        nextMetadata.remove('currentModelCode');
      } else {
        nextMetadata['currentModelCode'] = normalizedModelMode;
      }
    }

    final encodedMetadata = await _encodeSessionMetadataPayload(
      sessionId: sessionId,
      metadata: nextMetadata,
    );
    final expectedVersion = session.metadataVersion ?? 0;
    final response = await SocketRepository.instance.updateSessionMetadata(
      sessionId: sessionId,
      metadata: encodedMetadata,
      expectedVersion: expectedVersion,
    );
    final result = response['result']?.toString();
    if (result == 'version-mismatch') {
      await loadSessions(force: true);
      return;
    }
    if (result != null && result != 'success') {
      throw Exception('update-metadata failed: $result');
    }

    final nextVersion = _parseSeq(response['version']) ?? expectedVersion + 1;
    final resolvedPermissionMode = _resolveLocalSessionMode(
      preferred: !identical(
        permissionMode,
        SessionServiceNotifier._sessionOverrideSentinel,
      )
          ? permissionMode as String?
          : session.permissionMode,
      explicit: session.permissionMode,
      metadataValue: nextMetadata['currentOperatingModeCode']?.toString(),
    );
    final resolvedModelMode = _resolveLocalSessionMode(
      preferred: !identical(
        modelMode,
        SessionServiceNotifier._sessionOverrideSentinel,
      )
          ? modelMode as String?
          : session.modelMode,
      explicit: session.modelMode,
      metadataValue: nextMetadata['currentModelCode']?.toString(),
    );
    _repository.applySessions([
      session.copyWith(
        title: _resolveSessionTitle(
          path: nextMetadata['path']?.toString() ?? session.path,
          summary: _asStringMap(nextMetadata['summary'])?['text']?.toString(),
          name: nextMetadata['name']?.toString(),
          title: nextMetadata['title']?.toString(),
          fallback: session.title,
        ),
        metadata: nextMetadata,
        metadataVersion: nextVersion,
        permissionMode: resolvedPermissionMode,
        modelMode: resolvedModelMode,
      ),
    ]);
  }
}
