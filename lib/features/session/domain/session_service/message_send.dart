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
    final bridgeStopper = Completer<void>();
    final existingMessages = _repository.getSessionMessages(sessionId);
    unawaited(
      _pollSessionMessagesDuringSend(
        sessionId: sessionId,
        stopSignal: bridgeStopper.future,
      ),
    );
    try {
      final session = _repository.getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      final browsingOlderHistory = existingMessages?.hasNewerMessages == true;
      if (!browsingOlderHistory) {
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
      }

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
      if (!bridgeStopper.isCompleted) {
        bridgeStopper.complete();
      }
      unawaited(loadSessionMessages(
        sessionId,
        force: browsingOlderHistory,
        messageWindowSize:
            SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
      ).catchError((Object error) {
        Logger.warning('Failed to refresh session messages after send: $error');
      }));

      Logger.info('Message sent to session: $sessionId');
    } catch (error) {
      if (!bridgeStopper.isCompleted) {
        bridgeStopper.complete();
      }
      if (existingMessages?.hasNewerMessages != true) {
        _repository.removeMessage(sessionId, resolvedLocalId);
      }
      Logger.error('Send message error: $error');
      rethrow;
    }
  }

  Future<void> _pollSessionMessagesDuringSend({
    required String sessionId,
    required Future<void> stopSignal,
  }) async {
    final stopCompleter = Completer<void>();
    stopSignal.whenComplete(() {
      if (!stopCompleter.isCompleted) stopCompleter.complete();
    });

    while (!stopCompleter.isCompleted) {
      await Future.any<void>([
        stopCompleter.future,
        Future<void>.delayed(const Duration(milliseconds: 450)),
      ]);
      if (stopCompleter.isCompleted) {
        break;
      }
      try {
        await loadSessionMessages(
          sessionId,
          messageWindowSize:
              SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
        );
      } catch (error) {
        Logger.warning(
          'Failed to poll session messages during send for $sessionId: $error',
        );
      }
    }
  }

  Future<T> _requestSessionMessages<T>({
    required String sessionId,
    required Future<T> Function(String path) action,
  }) async {
    // Always prefer /v3 over /v1: /v3 supports cursor-based pagination
    // (after_seq + hasMore) which is required for complete message sync.
    // /v1 returns a fixed 150-message window in desc order with no pagination.
    final prefixes = <String>[
      '/v3',
      if (_sessionMessagesApiPrefix != null &&
          _sessionMessagesApiPrefix != '/v3')
        _sessionMessagesApiPrefix!,
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
