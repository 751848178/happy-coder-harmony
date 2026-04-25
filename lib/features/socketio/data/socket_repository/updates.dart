part of 'socket_repository.dart';

extension SocketRepositoryUpdates on SocketRepository {
  void _handleIncomingMessage(
    dynamic data, {
    SocketMessageType type = SocketMessageType.user,
  }) {
    try {
      final messageData = _asStringMap(data);
      if (messageData == null) return;
      final messageId = messageData['id']?.toString();
      if (messageId == null || messageId.isEmpty) return;
      if (_deduplicationSet.contains(messageId)) {
        Logger.debug('Duplicate message ignored: $messageId');
        return;
      }
      _deduplicationSet.add(messageId);

      final message = SocketMessage(
        id: messageId,
        type: type,
        content: messageData['content']?.toString() ?? '',
        sessionId: _resolveSocketSessionId(messageData),
        metadata: _asStringMap(messageData['metadata']),
        timestamp: _parseDateTime(messageData['timestamp']) ?? DateTime.now(),
      );

      _messageController.add(message);
      _eventController.add(SocketEvent.messageReceived(message));
    } catch (e) {
      Logger.error('Failed to handle incoming message: $e');
    }
  }

  Future<void> _handleUpdatePayload(dynamic data) async {
    try {
      final payload = _asStringMap(data);
      final body = _asStringMap(payload?['body']);
      switch (body?['t'] as String?) {
        case 'new-session':
          final sessionJson = <String, dynamic>{
            'id': body?['id'] ?? body?['sessionId'],
            'seq': body?['seq'],
            'createdAt': body?['createdAt'] ?? payload?['createdAt'],
            'updatedAt': body?['updatedAt'] ?? payload?['createdAt'],
            'active': body?['active'],
            'activeAt': body?['activeAt'],
            'metadata': body?['metadata'],
            'metadataVersion': body?['metadataVersion'],
            'agentState': body?['agentState'],
            'agentStateVersion': body?['agentStateVersion'],
            'dataEncryptionKey': body?['dataEncryptionKey'],
          };
          try {
            final newSessionId = sessionJson['id']?.toString();
            final secretKey = await _tokenStorage.getSecretKey();
            final encryptedDataKey =
                sessionJson['dataEncryptionKey']?.toString();
            final dataKey = secretKey != null &&
                    secretKey.isNotEmpty &&
                    encryptedDataKey != null &&
                    encryptedDataKey.isNotEmpty
                ? await (await CryptoService.instance)
                    .decryptHappyCoderDataEncryptionKey(
                    encryptedDataKey,
                    secretKey,
                  )
                : null;
            final metadata = await decodeSessionUpdateJsonMap(
              rawValue: sessionJson['metadata'],
              sessionKey: dataKey,
              secretKey: secretKey,
            );
            final agentState = await decodeSessionUpdateJsonMap(
              rawValue: sessionJson['agentState'],
              sessionKey: dataKey,
              secretKey: secretKey,
            );
            if (metadata != null) sessionJson['metadata'] = metadata;
            if (agentState != null) sessionJson['agentState'] = agentState;
            if (newSessionId != null && dataKey != null) {
              SessionDataKeyStore.instance.setSessionKey(newSessionId, dataKey);
            }
          } catch (e) {
            Logger.warning(
              'Failed to decrypt new-session payload, '
              'applying with raw data: $e',
            );
          }
          _sessionRepository.applySessions([Session.fromJson(sessionJson)]);
          break;
        case 'update-session':
          final sessionId = body?['id']?.toString() ?? body?['sid']?.toString();
          if (sessionId == null) return;
          final existing = _sessionRepository.getSession(sessionId);
          if (existing == null) return;
          final metadataUpdate = _asStringMap(body?['metadata']);
          final agentStateUpdate = _asStringMap(body?['agentState']);
          final metadataVersion =
              metadataUpdate?['version'] as int? ?? existing.metadataVersion;
          final agentStateVersion = agentStateUpdate?['version'] as int? ??
              existing.agentStateVersion;
          Map<String, dynamic>? nextMetadata;
          Map<String, dynamic>? nextAgentState;
          try {
            nextMetadata = await decodeSessionUpdateJsonMap(
                  rawValue: metadataUpdate?['value'],
                  sessionKey: SessionDataKeyStore.instance.sessionKeyFor(
                    sessionId,
                  ),
                  secretKey: await _tokenStorage.getSecretKey(),
                ) ??
                existing.metadata;
            nextAgentState = await decodeSessionUpdateJsonMap(
                  rawValue: agentStateUpdate?['value'],
                  sessionKey: SessionDataKeyStore.instance.sessionKeyFor(
                    sessionId,
                  ),
                  secretKey: await _tokenStorage.getSecretKey(),
                ) ??
                existing.agentState;
          } catch (e) {
            Logger.warning(
              'Failed to decrypt update-session payload for $sessionId, '
              'skipping update: $e',
            );
            return;
          }
          final nextTitle = nextMetadata?['name']?.toString() ??
              nextMetadata?['title']?.toString() ??
              existing.title;
          final nextModelMode = _resolveUpdatedMode(
            existing.modelMode,
            nextMetadata?['currentModelCode']?.toString(),
          );
          final nextPermissionMode = _resolveUpdatedMode(
            existing.permissionMode,
            nextMetadata?['currentOperatingModeCode']?.toString(),
          );
          _sessionRepository.applySessions([
            existing.copyWith(
              title: nextTitle,
              metadata: nextMetadata,
              metadataVersion: metadataVersion,
              modelMode: nextModelMode,
              permissionMode: nextPermissionMode,
              agentState: nextAgentState,
              agentStateVersion: agentStateVersion,
              updatedAt: resolveSessionUpdatedAtForRealtimeUpdate(
                currentUpdatedAt: existing.updatedAt,
                sessionUpdatedAt: _parseDateTime(
                  body?['updatedAt'] ?? payload?['updatedAt'],
                ),
                eventCreatedAt: _parseDateTime(payload?['createdAt']),
              ),
            ),
          ]);
          break;
        case 'delete-session':
          final sessionId = body?['sid'] as String?;
          if (sessionId != null) {
            _sessionRepository.deleteSession(sessionId);
            unawaited(_clearLocalSessionCache(sessionId));
          }
          break;
        case 'new-message':
          final sessionId = body?['sid'] as String?;
          final messageJson = _asStringMap(body?['message']);
          if (sessionId == null || messageJson == null) {
            return;
          }
          final socketMessage = SocketMessage(
            id: messageJson['id']?.toString() ??
                payload?['id']?.toString() ??
                '',
            type: SocketMessageType.server,
            content: '',
            sessionId: sessionId,
            metadata: const {'source': 'new-message'},
            timestamp:
                _parseDateTime(messageJson['createdAt']) ?? DateTime.now(),
          );
          _messageController.add(socketMessage);
          _eventController.add(SocketEvent.messageReceived(socketMessage));
          break;
      }
    } catch (e) {
      Logger.error('Failed to handle update payload: $e');
    }
  }

  void _handleEphemeralPayload(dynamic data) {
    try {
      final payload = _asStringMap(data);
      if (payload?['type'] != 'activity') {
        return;
      }
      final sessionId = payload?['id'] as String?;
      if (sessionId == null) {
        return;
      }
      final existing = _sessionRepository.getSession(sessionId);
      if (existing == null) {
        return;
      }

      final nextSession = applyEphemeralSessionActivity(
        session: existing,
        active: payload?['active'] as bool?,
        activeAt: _parseDateTime(payload?['activeAt']) ?? existing.activeAt,
        thinkingProvided: payload?.containsKey('thinking') == true,
        thinking: payload?['thinking'] as bool?,
      );
      final lastAppliedAt = _lastEphemeralSessionApplyAt[sessionId];
      final onlyHeartbeatAdvance = existing.active == nextSession.active &&
          existing.thinking == nextSession.thinking &&
          existing.activeAt != null &&
          nextSession.activeAt != null &&
          nextSession.activeAt!.isAfter(existing.activeAt!);

      if (existing.active == nextSession.active &&
          existing.activeAt == nextSession.activeAt &&
          existing.thinking == nextSession.thinking &&
          existing.thinkingAt == nextSession.thinkingAt) {
        return;
      }
      if (onlyHeartbeatAdvance &&
          lastAppliedAt != null &&
          DateTime.now().difference(lastAppliedAt) <
              const Duration(seconds: 2)) {
        return;
      }
      _lastEphemeralSessionApplyAt[sessionId] = DateTime.now();
      _sessionRepository.applySessions([nextSession]);
    } catch (e) {
      Logger.error('Failed to handle ephemeral payload: $e');
    }
  }

  void _handleToolCallRequest(dynamic data) {
    try {
      final toolData = _asStringMap(data);
      if (toolData == null) return;
      final toolId = toolData['id']?.toString();
      final sessionId = _resolveSocketSessionId(toolData);
      if (toolId == null ||
          toolId.isEmpty ||
          sessionId == null ||
          sessionId.isEmpty) {
        return;
      }

      final request = ToolCallRequest(
        id: toolId,
        sessionId: sessionId,
        toolName: toolData['name'] as String? ?? 'unknown',
        toolDescription: toolData['description'] as String?,
        parameters: toolData['parameters'] as Map<String, dynamic>?,
      );
      Logger.info(
          'Tool call request: $toolId (${request.toolName}) for session: $sessionId');
      _toolCallRequestController.add(request);
    } catch (e) {
      Logger.error('Failed to handle tool call request: $e');
    }
  }

  String? _resolveSocketSessionId(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }
    for (final key in const ['sessionId', 'sid', 'session_id', 'session']) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return null;
  }
}

/// When a local mode is 'default' or null (meaning "use remote default"),
/// adopt the metadata value from the PC. When the user explicitly chose a
/// non-default mode, keep that choice.
String? _resolveUpdatedMode(String? localValue, String? metadataValue) {
  if (localValue != null && localValue != 'default') {
    return localValue;
  }
  return metadataValue ?? localValue;
}
