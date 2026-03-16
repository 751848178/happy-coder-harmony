part of 'session_service.dart';

extension SessionServiceSessionCreation on SessionServiceNotifier {
  Future<String?> createSession({
    String? title,
    String? tag,
    String? path,
    Map<String, dynamic>? metadata,
    String? permissionMode,
    String? modelMode,
  }) async {
    try {
      final resolvedTitle = (title?.trim().isNotEmpty ?? false)
          ? title!.trim()
          : (tag?.trim().isNotEmpty ?? false)
              ? tag!.trim()
              : '新建会话';
      final resolvedTag = (tag?.trim().isNotEmpty ?? false)
          ? tag!.trim()
          : 'session_${DateTime.now().millisecondsSinceEpoch}';
      final requestMetadata = <String, dynamic>{
        'name': resolvedTitle,
        if (path != null && path.isNotEmpty) 'path': path,
        if (permissionMode != null) 'permissionMode': permissionMode,
        if (modelMode != null) 'modelMode': modelMode,
        ...?metadata,
      };
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        '/v1/sessions',
        data: {
          'tag': resolvedTag,
          'metadata': jsonEncode(requestMetadata),
          'agentState': null,
          'dataEncryptionKey': null,
        },
      );
      final sessionJson = _asStringMap(response['session']) ?? response;
      if (sessionJson.isEmpty || !sessionJson.containsKey('id')) {
        return null;
      }

      final newSession = Session.fromJson(sessionJson);
      _repository.applySessions([newSession]);
      await _persistSessionCreationModes(
        sessionId: newSession.id,
        permissionMode: permissionMode,
        modelMode: modelMode,
      );
      Logger.info('Session created: ${newSession.id}');
      return newSession.id;
    } catch (error) {
      Logger.error('Create session error: $error');
      return null;
    }
  }

  Future<SessionSpawnResult> spawnSession({
    required String machineId,
    required String directory,
    required String agent,
    bool approvedNewDirectoryCreation = false,
    Map<String, String>? environmentVariables,
    String? permissionMode,
    String? modelMode,
  }) async {
    try {
      await _ensureMachineRpcContext(machineId);
      final normalizedAgent = normalizeSessionAgent(agent);
      final result = await SocketRepository.instance.machineRpc(
        machineId: machineId,
        method: 'spawn-happy-session',
        payload: {
          'type': 'spawn-in-directory',
          'directory': directory,
          'approvedNewDirectoryCreation': approvedNewDirectoryCreation,
          'agent': normalizedAgent,
          if (environmentVariables != null && environmentVariables.isNotEmpty)
            'environmentVariables': environmentVariables,
        },
        dataEncryptionKey: _machineDataKeys[machineId],
        accountSecret: _accountSecret,
      );
      final response = _asStringMap(result);
      switch (response?['type']?.toString()) {
        case 'success':
          final sessionId = response?['sessionId']?.toString();
          if (sessionId == null || sessionId.isEmpty) {
            return const SessionSpawnResult.error('创建会话失败：缺少会话 ID');
          }
          final sessionLoaded = await _awaitSessionAvailable(sessionId);
          if (!sessionLoaded) {
            _seedLocalSpawnedSession(
              sessionId: sessionId,
              machineId: machineId,
              directory: directory,
              agent: normalizedAgent,
              permissionMode: permissionMode,
              modelMode: modelMode,
            );
            unawaited(loadSessions(force: true).catchError((Object error) {
              Logger.warning(
                'Failed to refresh sessions after spawn for $sessionId: $error',
              );
            }));
          }
          await _persistSessionCreationModes(
            sessionId: sessionId,
            permissionMode: permissionMode,
            modelMode: modelMode,
          );
          return SessionSpawnResult.success(sessionId);
        case 'requestToApproveDirectoryCreation':
          final approvalPath = response?['directory']?.toString() ?? directory;
          return SessionSpawnResult.directoryApproval(approvalPath);
        case 'error':
          return SessionSpawnResult.error(
            response?['errorMessage']?.toString() ?? '创建会话失败',
          );
        default:
          return SessionSpawnResult.error(
            response?['errorMessage']?.toString() ?? '创建会话失败',
          );
      }
    } catch (error) {
      Logger.error('Spawn session error: $error');
      return SessionSpawnResult.error(error.toString());
    }
  }

  Future<bool> _awaitSessionAvailable(String sessionId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await loadSessions(force: true);
      } catch (error) {
        Logger.warning(
          'Failed to refresh sessions while waiting for $sessionId: $error',
        );
      }
      if (_repository.getSession(sessionId) != null) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }
}
