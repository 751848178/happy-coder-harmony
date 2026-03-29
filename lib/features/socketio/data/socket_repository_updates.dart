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

  void _handleUpdatePayload(dynamic data) {
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
          _sessionRepository.applySessions([Session.fromJson(sessionJson)]);
          break;
        case 'update-session':
          final sessionId = body?['id'] as String?;
          if (sessionId == null) return;
          final existing = _sessionRepository.getSession(sessionId);
          if (existing == null) return;
          final metadataUpdate = _asStringMap(body?['metadata']);
          final agentStateUpdate = _asStringMap(body?['agentState']);
          final nextMetadata = _decodeMaybeJsonMap(metadataUpdate?['value']) ??
              existing.metadata;
          final nextAgentState =
              _decodeMaybeJsonMap(agentStateUpdate?['value']) ??
                  existing.agentState;
          final nextTitle = nextMetadata?['name']?.toString() ??
              nextMetadata?['title']?.toString() ??
              existing.title;
          _sessionRepository.applySessions([
            existing.copyWith(
              title: nextTitle,
              metadata: nextMetadata,
              metadataVersion: metadataUpdate?['version'] as int? ??
                  existing.metadataVersion,
              agentState: nextAgentState,
              agentStateVersion: agentStateUpdate?['version'] as int? ??
                  existing.agentStateVersion,
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
