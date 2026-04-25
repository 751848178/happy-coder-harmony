part of 'session_service.dart';

extension _SessionServiceMessageArchiveRemoteSync
    on _SessionServiceMessageArchiveCoordinator {
  Future<void> syncFullSessionMessagesFromRemote(
    String sessionId, {
    bool throwOnError = false,
  }) async {
    try {
      await _runArchiveHydrationTask(
        sessionId,
        throwOnError: true,
        forceSync: true,
      );
    } catch (error) {
      Logger.error(
        'Session full message archive sync failed for $sessionId: $error',
      );
      if (throwOnError) {
        rethrow;
      }
    }
  }

  Future<void> _runArchiveHydrationTask(
    String sessionId, {
    required bool throwOnError,
    bool forceSync = false,
  }) async {
    final inFlight = _notifier._archiveHydrationInFlight[sessionId];
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (error) {
        if (throwOnError) {
          rethrow;
        }
      }
      return;
    }
    final task = _syncFullSessionMessagesFromRemoteInternal(
      sessionId,
      forceSync: forceSync,
    );
    _notifier._archiveHydrationInFlight[sessionId] = task;
    try {
      await task;
    } catch (error) {
      if (throwOnError) {
        rethrow;
      }
    } finally {
      if (identical(_notifier._archiveHydrationInFlight[sessionId], task)) {
        _notifier._archiveHydrationInFlight.remove(sessionId);
      }
    }
  }

  Future<void> _syncFullSessionMessagesFromRemoteInternal(
    String sessionId, {
    bool forceSync = false,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (_notifier.getSession(sessionId) == null ||
        !_notifier._sessionDataKeys.containsKey(sessionId)) {
      await _notifier.loadSessions(
        force: _notifier.getSession(sessionId) == null,
      );
    }
    final sessionKey = _notifier._sessionDataKeys[sessionId];
    final existingSummary =
        await StorageService.instance.getSessionMessageArchiveSummary(
      sessionId,
    );
    final expectedMessageCount = _resolveExpectedArchiveMessageCount(
      sessionId,
      existing: existing,
    );
    if (!forceSync &&
        _isArchiveSummaryCompleteForExpectedCount(
          existingSummary,
          expectedMessageCount: expectedMessageCount,
        )) {
      Logger.info(
        '[SessionArchive] sync skipped session=$sessionId '
        'count=${existingSummary.messageCount} '
        'expected=$expectedMessageCount complete=true',
      );
      return;
    }
    if (existingSummary.isComplete &&
        expectedMessageCount > 0 &&
        existingSummary.messageCount < expectedMessageCount) {
      Logger.warning(
        'Archive summary was marked complete but message count is short; '
        'continuing hydration: $sessionId '
        '(archived=${existingSummary.messageCount}, expected=$expectedMessageCount, '
        'lastSeq=${existingSummary.lastRemoteSeq})',
      );
    }

    var afterSeq = existingSummary.lastRemoteSeq;
    var totalFetchedMessageCount = existingSummary.messageCount;
    if (existingSummary.messageCount > 0 &&
        existingSummary.lastRemoteSeq <= 0) {
      Logger.warning(
        'Partial session archive is missing resume cursor; restarting sync: '
        '$sessionId (count=${existingSummary.messageCount})',
      );
      await StorageService.instance.clearSessionMessageArchive(sessionId);
      afterSeq = 0;
      totalFetchedMessageCount = 0;
    } else if (existingSummary.messageCount <= 0) {
      await StorageService.instance.clearSessionMessageArchive(sessionId);
    }
    Logger.info(
      '[SessionArchive] sync start session=$sessionId '
      'resumeCount=$totalFetchedMessageCount resumeSeq=$afterSeq '
      'complete=${existingSummary.isComplete}',
    );

    var hasMore = true;
    var loadedPages = 0;

    while (hasMore) {
      final response = await _notifier._requestSessionMessages<dynamic>(
        sessionId: sessionId,
        action: (path) => ApiService.instance.get<dynamic>(
          path,
          queryParameters: {
            'after_seq': afterSeq,
            'limit':
                _SessionServiceMessageArchiveCoordinator.archiveSyncPageSize,
          },
          options: Options(receiveTimeout: const Duration(seconds: 90)),
        ),
      );
      final responseMap = _notifier._asStringMap(response);
      final messageItems = _notifier._extractListPayload(
        response,
        'messages',
        fallbackKeys: const ['items', 'data', 'results'],
      );
      var maxSeq = afterSeq;
      final archivedBatch = <ReducerMessage>[];

      for (var i = 0;
          i < messageItems.length;
          i += _SessionServiceMessageArchiveCoordinator
              .archiveSyncParseConcurrency) {
        final chunk = messageItems.sublist(
          i,
          i +
                      _SessionServiceMessageArchiveCoordinator
                          .archiveSyncParseConcurrency >
                  messageItems.length
              ? messageItems.length
              : i +
                  _SessionServiceMessageArchiveCoordinator
                      .archiveSyncParseConcurrency,
        );
        final chunkResults = await Future.wait(
          chunk.map((item) async {
            final messageJson = _notifier._asStringMap(item);
            if (messageJson == null) {
              return null;
            }
            final seq = _notifier._parseSeq(messageJson['seq']);
            try {
              final parsedMessages = await _notifier._parseServerMessages(
                messageJson,
                sessionKey: sessionKey,
                secretKey: _notifier._accountSecret,
              );
              return (seq, parsedMessages);
            } catch (error) {
              Logger.warning(
                'Failed to parse message for archive sync: $error',
              );
              return null;
            }
          }),
        );
        for (final result in chunkResults) {
          if (result == null) {
            continue;
          }
          final (seq, parsedMessages) = result;
          if (seq != null && seq > maxSeq) {
            maxSeq = seq;
          }
          for (final parsedMessage in parsedMessages) {
            final archiveIndex = totalFetchedMessageCount;
            final archivedMessage = _attachArchiveIndex(
              parsedMessage,
              archiveIndex,
            );
            totalFetchedMessageCount += 1;
            archivedBatch.add(archivedMessage);
          }
        }
      }

      if (archivedBatch.isNotEmpty) {
        final batchStartIndex = totalFetchedMessageCount - archivedBatch.length;
        await StorageService.instance.appendSessionMessageArchiveChunk(
          sessionId,
          archivedBatch,
          startIndex: batchStartIndex,
        );
        await StorageService.instance.saveSessionMessageArchiveSummary(
          sessionId,
          messageCount: totalFetchedMessageCount,
          isComplete: false,
          lastRemoteSeq: maxSeq,
        );
      }

      final responseHasMore =
          responseMap?['hasMore'] == true || responseMap?['has_more'] == true;
      final inferredHasMore = !responseHasMore &&
          messageItems.length >=
              _SessionServiceMessageArchiveCoordinator.archiveSyncPageSize &&
          maxSeq > afterSeq;
      hasMore = responseHasMore || inferredHasMore;
      loadedPages += 1;
      if (loadedPages == 1 || loadedPages % 5 == 0 || !hasMore) {
        Logger.info(
          '[SessionArchive] sync progress session=$sessionId '
          'pages=$loadedPages fetched=$totalFetchedMessageCount '
          'lastSeq=$afterSeq nextSeq=$maxSeq hasMore=$hasMore',
        );
      }
      if (maxSeq == afterSeq) {
        hasMore = false;
      }
      afterSeq = maxSeq;
    }

    _notifier._sessionLastSeq[sessionId] = afterSeq;
    await StorageService.instance.saveSessionMessageArchiveSummary(
      sessionId,
      messageCount: totalFetchedMessageCount,
      isComplete: true,
      lastRemoteSeq: afterSeq,
    );
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Session full message archive sync completed: $sessionId '
      '(total=$totalFetchedMessageCount, pages=$loadedPages, '
      'resumeSeq=$afterSeq)',
    );
  }
}
