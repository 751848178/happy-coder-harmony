part of 'session_service.dart';

extension SessionServiceMessageSend on SessionServiceNotifier {
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
    String? localId,
  }) async {
    final resolvedLocalId =
        localId ?? 'msg_${DateTime.now().microsecondsSinceEpoch}';
    try {
      final session = _repository.getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      _repository.applyMessages(sessionId, [
        ReducerMessage(
          id: resolvedLocalId,
          kind: 'text',
          createdAt: DateTime.now(),
          text: content,
          metadata: {
            'role': 'user',
            'localId': resolvedLocalId,
            'optimistic': true,
            ...?metadata,
          },
        ),
      ]);

      final encryptedContent = await _encryptSessionMessage(
        sessionId: sessionId,
        rawRecord: _buildOutboundRawRecord(
          session: session,
          text: content,
          metadata: metadata,
        ),
      );
      await _requestSessionMessages<dynamic>(
        sessionId: sessionId,
        action: (path) => ApiService.instance.post<dynamic>(
          path,
          data: {
            'messages': [
              {'content': encryptedContent, 'localId': resolvedLocalId},
            ],
          },
        ),
      );
      unawaited(loadSessionMessages(sessionId).catchError((Object error) {
        Logger.warning('Failed to refresh session messages after send: $error');
      }));

      Logger.info('Message sent to session: $sessionId');
    } catch (error) {
      _repository.removeMessage(sessionId, resolvedLocalId);
      Logger.error('Send message error: $error');
      rethrow;
    }
  }

  Future<T> _requestSessionMessages<T>({
    required String sessionId,
    required Future<T> Function(String path) action,
  }) async {
    final prefixes = <String>[
      if (_sessionMessagesApiPrefix != null) _sessionMessagesApiPrefix!,
      '/v1',
      '/v3',
    ].toSet().toList(growable: false);
    Object? lastError;

    for (final prefix in prefixes) {
      final path = '$prefix/sessions/$sessionId/messages';
      try {
        final response = await action(path);
        if (_sessionMessagesApiPrefix != prefix) {
          Logger.info('Resolved session messages endpoint: $prefix');
        }
        _sessionMessagesApiPrefix = prefix;
        return response;
      } catch (error) {
        lastError = error;
        if (_isMissingSessionMessagesEndpoint(error)) {
          Logger.warning(
              'Session messages endpoint unavailable at $path: $error');
          continue;
        }
        rethrow;
      }
    }

    throw lastError ?? Exception('No session messages endpoint available');
  }

  bool _isMissingSessionMessagesEndpoint(Object error) {
    final message = error.toString();
    return message.contains('(404)') ||
        message.contains(' 404') ||
        message.contains('404:') ||
        message.contains('status code of 404');
  }
}
