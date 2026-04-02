part of 'session_service.dart';

extension SessionServiceMessageOperations on SessionServiceNotifier {
  static const int _sessionMessagesPageSize = 100;

  Future<void> loadSessionMessages(
    String sessionId, {
    bool force = false,
    bool throwOnError = false,
    bool preserveOptimisticMessages = true,
    int? maxPages,
  }) async {
    try {
      final sessionKey = _sessionDataKeys[sessionId];
      final existing = _repository.getSessionMessages(sessionId);
      final previousCount = existing?.messages.length ?? 0;
      var afterSeq = force
          ? 0
          : (existing == null ? 0 : (_sessionLastSeq[sessionId] ?? 0));
      var hasMore = true;
      var loadedPages = 0;
      final pageLimit = maxPages == null || maxPages <= 0 ? null : maxPages;
      final messages = <ReducerMessage>[];

      while (hasMore) {
        final response = await _requestSessionMessages<dynamic>(
          sessionId: sessionId,
          action: (path) => ApiService.instance.get<dynamic>(
            path,
            queryParameters: {
              'after_seq': afterSeq,
              'limit': _sessionMessagesPageSize,
            },
          ),
        );
        final messageItems = _extractListPayload(
          response,
          'messages',
          fallbackKeys: const ['items', 'data', 'results'],
        );
        final responseMap = _asStringMap(response);
        var maxSeq = afterSeq;

        // Parse messages in parallel within the page to reduce total
        // decryption time (sequential await per message was 264 individual
        // yields; parallel cuts wall-clock to ~page_size/floor(parallelism)).
        final pageResults = await Future.wait(
          messageItems.map((item) async {
            final messageJson = _asStringMap(item);
            if (messageJson == null) return null;
            final seq = _parseSeq(messageJson['seq']);
            try {
              final parsedMessages = await _parseServerMessages(
                messageJson,
                sessionKey: sessionKey,
                secretKey: _accountSecret,
              );
              return (seq, parsedMessages);
            } catch (error) {
              Logger.warning('Failed to parse message: $error');
              return null;
            }
          }),
        );
        for (final result in pageResults) {
          if (result == null) continue;
          final (seq, parsedMessages) = result;
          if (seq != null && seq > maxSeq) {
            maxSeq = seq;
          }
          messages.addAll(parsedMessages);
        }

        final responseHasMore =
            responseMap?['hasMore'] == true || responseMap?['has_more'] == true;
        final inferredHasMore = !responseHasMore &&
            messageItems.length >= _sessionMessagesPageSize &&
            maxSeq > afterSeq;
        hasMore = responseHasMore || inferredHasMore;
        loadedPages += 1;
        if (pageLimit != null && loadedPages >= pageLimit) {
          hasMore = false;
        }
        if (maxSeq == afterSeq) {
          hasMore = false;
        }
        afterSeq = maxSeq;
      }

      _sessionLastSeq[sessionId] = afterSeq;
      if (force) {
        // When force-reloading produces zero parsed messages but the server
        // response contained message items (i.e. decryption failed silently),
        // keep the existing messages instead of replacing them with an empty
        // list.  This prevents the UI from showing an empty-state placeholder
        // when the actual cause is a missing/stale session data key.
        if (messages.isEmpty &&
            existing != null &&
            existing.messages.isNotEmpty) {
          Logger.warning(
            'Session messages force-reload produced empty result for $sessionId; '
            'keeping ${existing.messages.length} existing messages to avoid data loss',
          );
        } else {
          _repository.replaceMessages(
            sessionId,
            messages,
            preserveOptimisticMessages: preserveOptimisticMessages,
          );
        }
      } else if (messages.isNotEmpty ||
          existing == null ||
          existing.isLoaded == false) {
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

  Future<void> syncFullSessionMessagesFromRemote(
    String sessionId, {
    bool throwOnError = false,
  }) async {
    try {
      await loadSessionMessages(
        sessionId,
        force: true,
        throwOnError: true,
        preserveOptimisticMessages: false,
      );
      await _persistSessionCacheImmediately(sessionId);
      Logger.info('Session full message sync completed: $sessionId');
    } catch (error) {
      Logger.error('Session full message sync failed for $sessionId: $error');
      if (throwOnError) {
        rethrow;
      }
    }
  }

  Future<void> refreshSessionMessageSnapshots(
    Iterable<String> sessionIds, {
    int batchSize = 4,
    bool force = false,
    int? maxPagesPerSession,
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
      'Refreshing session message snapshots for ${ids.length} sessions '
      '(force=$force, batchSize=$batchSize)',
    );
    for (var start = 0; start < ids.length; start += batchSize) {
      final end =
          (start + batchSize) > ids.length ? ids.length : start + batchSize;
      final batch = ids.sublist(start, end);
      await Future.wait([
        for (final sessionId in batch)
          () {
            final existing = _repository.getSessionMessages(sessionId);
            final shouldLimitPages = !force &&
                maxPagesPerSession != null &&
                maxPagesPerSession > 0 &&
                existing?.isLoaded == true;
            return loadSessionMessages(
              sessionId,
              force: force,
              throwOnError: true,
              maxPages: shouldLimitPages ? maxPagesPerSession : null,
            );
          }(),
      ]);
    }
  }

  Future<void> _warmSessionPreviewData(
    List<Session> sessions, {
    bool force = false,
  }) async {
    final sessionsToRefresh = sessions.toList(growable: false);
    for (var start = 0; start < sessionsToRefresh.length; start += 4) {
      final end = (start + 4) > sessionsToRefresh.length
          ? sessionsToRefresh.length
          : start + 4;
      final batch = sessionsToRefresh.sublist(start, end);
      await Future.wait([
        for (final session in batch)
          () async {
            final existing = _repository.getSessionMessages(session.id);
            if (!force && existing?.isLoaded == true) {
              return;
            }
            try {
              await loadSessionMessages(session.id, force: force);
            } catch (error) {
              Logger.warning(
                  'Failed to warm preview data for ${session.id}: $error');
            }
          }(),
      ]);
    }
  }
}
