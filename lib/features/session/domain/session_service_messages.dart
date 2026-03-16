part of 'session_service.dart';

extension SessionServiceMessageOperations on SessionServiceNotifier {
  Future<void> loadSessionMessages(
    String sessionId, {
    bool force = false,
    bool throwOnError = false,
  }) async {
    try {
      final sessionKey = _sessionDataKeys[sessionId];
      final existing = _repository.getSessionMessages(sessionId);
      final previousCount = existing?.messages.length ?? 0;
      var afterSeq = force
          ? 0
          : (existing == null ? 0 : (_sessionLastSeq[sessionId] ?? 0));
      var hasMore = true;
      final messages = <ReducerMessage>[];

      while (hasMore) {
        final response = await _requestSessionMessages<dynamic>(
          sessionId: sessionId,
          action: (path) => ApiService.instance.get<dynamic>(
            path,
            queryParameters: {'after_seq': afterSeq, 'limit': 100},
          ),
        );
        final messageItems = _extractListPayload(
          response,
          'messages',
          fallbackKeys: const ['items', 'data', 'results'],
        );
        final responseMap = _asStringMap(response);
        var maxSeq = afterSeq;

        for (final item in messageItems) {
          final messageJson = _asStringMap(item);
          if (messageJson == null) {
            continue;
          }
          final seq = _parseSeq(messageJson['seq']);
          if (seq != null && seq > maxSeq) {
            maxSeq = seq;
          }
          try {
            final parsedMessages = await _parseServerMessages(
              messageJson,
              sessionKey: sessionKey,
              secretKey: _accountSecret,
            );
            messages.addAll(parsedMessages);
          } catch (error) {
            Logger.warning('Failed to parse message: $error');
          }
        }

        hasMore =
            responseMap?['hasMore'] == true || responseMap?['has_more'] == true;
        if (maxSeq == afterSeq) {
          hasMore = false;
        }
        afterSeq = maxSeq;
      }

      _sessionLastSeq[sessionId] = afterSeq;
      if (force) {
        _repository.replaceMessages(sessionId, messages);
      } else if (messages.isNotEmpty || existing == null) {
        _repository.applyMessages(sessionId, messages);
      }
      final refreshedCount =
          _repository.getSessionMessages(sessionId)?.messages.length ?? 0;
      Logger.info(
        force
            ? 'Session messages reloaded: $sessionId '
                '(server=${messages.length}, local=$previousCount->$refreshedCount)'
            : 'Session messages loaded: $sessionId '
                '(server=${messages.length}, local=$previousCount->$refreshedCount)',
      );
    } catch (error) {
      Logger.error('Load session messages error for $sessionId: $error');
      if (throwOnError) {
        rethrow;
      }
    }
  }

  Future<void> refreshSessionMessageSnapshots(
    Iterable<String> sessionIds, {
    int batchSize = 4,
  }) async {
    final ids = sessionIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    Logger.info(
        'Refreshing session message snapshots for ${ids.length} sessions');
    for (var start = 0; start < ids.length; start += batchSize) {
      final end =
          (start + batchSize) > ids.length ? ids.length : start + batchSize;
      final batch = ids.sublist(start, end);
      await Future.wait([
        for (final sessionId in batch)
          loadSessionMessages(sessionId, force: true, throwOnError: true),
      ]);
    }
  }

  Future<void> _warmSessionPreviewData(
    List<Session> sessions, {
    bool force = false,
  }) async {
    for (final session in sessions.take(3)) {
      final existing = _repository.getSessionMessages(session.id);
      if (!force && existing?.isLoaded == true) {
        continue;
      }
      try {
        await loadSessionMessages(session.id, force: force);
      } catch (error) {
        Logger.warning('Failed to warm preview data for ${session.id}: $error');
      }
    }
  }
}
