part of 'session_service.dart';

extension SessionServiceRpc on SessionServiceNotifier {
  Future<SessionBashResponse> executeSessionBash({
    required String sessionId,
    required String command,
    String? cwd,
    int? timeout,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'bash',
        payload:
            SessionBashRequest(command: command, cwd: cwd, timeout: timeout)
                .toJson(),
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionBashResponse(success: false, error: '无效的 bash 响应');
      }
      return SessionBashResponse.fromJson(map);
    } catch (error) {
      Logger.warning('Session bash RPC failed: $error');
      return SessionBashResponse(
        success: false,
        stderr: error.toString(),
        error: error.toString(),
      );
    }
  }

  Future<SessionReadFileResponse> readSessionFile({
    required String sessionId,
    required String path,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'readFile',
        payload: {'path': path},
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionReadFileResponse(
          success: false,
          error: '无效的文件读取响应',
        );
      }
      return SessionReadFileResponse.fromJson(map);
    } catch (error) {
      Logger.warning('Session readFile RPC failed: $error');
      return SessionReadFileResponse(success: false, error: error.toString());
    }
  }

  Future<SessionRipgrepResponse> executeSessionRipgrep({
    required String sessionId,
    required List<String> args,
    String? cwd,
  }) async {
    try {
      final result = await _callSessionRpcDecoded(
        sessionId: sessionId,
        method: 'ripgrep',
        payload: SessionRipgrepRequest(args: args, cwd: cwd).toJson(),
      );
      final map = _asStringMap(result);
      if (map == null) {
        return const SessionRipgrepResponse(
          success: false,
          error: '无效的 ripgrep 响应',
        );
      }
      return SessionRipgrepResponse.fromJson(map);
    } catch (error) {
      Logger.warning('Session ripgrep RPC failed: $error');
      return SessionRipgrepResponse(
        success: false,
        stderr: error.toString(),
        error: error.toString(),
      );
    }
  }

  Future<void> _submitPermissionDecision({
    required String sessionId,
    required Map<String, dynamic> request,
  }) async {
    final encryptedRequest = await _encryptSessionRpcPayload(
      sessionId: sessionId,
      payload: request,
    );
    await SocketRepository.instance.sessionRpc(
      sessionId: sessionId,
      method: 'permission',
      encryptedParams: encryptedRequest,
    );
  }

  Future<dynamic> _callSessionRpcDecoded({
    required String sessionId,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    await _ensureSessionRpcContext(sessionId);
    final encryptedRequest = await _encryptSessionRpcPayload(
      sessionId: sessionId,
      payload: payload,
    );
    final response = await SocketRepository.instance.sessionRpc(
      sessionId: sessionId,
      method: method,
      encryptedParams: encryptedRequest,
    );
    return _decryptSessionRpcResult(
        sessionId: sessionId, payload: response['result']);
  }

  Future<void> _ensureSessionRpcContext(String sessionId) async {
    if (_repository.getSession(sessionId) == null ||
        !_sessionDataKeys.containsKey(sessionId)) {
      await loadSessions(force: true);
    }
  }

  Future<void> _ensureMachineRpcContext(String machineId) async {
    if (_repository.getMachine(machineId) == null) {
      await loadMachines(force: true, allowFailure: true);
    }
    _accountSecret ??= await _tokenStorage.getSecretKey();
  }

  Future<dynamic> _decryptSessionRpcResult({
    required String sessionId,
    required dynamic payload,
  }) async {
    if (payload == null) {
      return null;
    }
    if (payload is! String || payload.trim().isEmpty) {
      return payload;
    }

    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(payload, sessionKey);
      if (decrypted != null) {
        return decrypted;
      }
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(payload, secretKey);
      if (decrypted != null) {
        return decrypted;
      }
    }
    return _decodeMaybeJsonValue(payload) ?? payload;
  }

  Future<String> _encryptSessionRpcPayload({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final crypto = await CryptoService.instance;
    final sessionKey = _sessionDataKeys[sessionId];
    if (sessionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(payload, sessionKey);
    }

    final secretKey = _accountSecret ?? await _tokenStorage.getSecretKey();
    if (secretKey != null && secretKey.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(payload, secretKey);
    }
    throw Exception('Missing session encryption key');
  }

  dynamic _decodeMaybeJsonValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }
}
