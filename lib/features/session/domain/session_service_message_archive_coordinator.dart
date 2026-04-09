part of 'session_service.dart';

class _SessionServiceMessageArchiveCoordinator {
  static const int archiveSyncPageSize = 40;
  static const int archiveSyncParseConcurrency = 8;

  const _SessionServiceMessageArchiveCoordinator(this._notifier);

  final SessionServiceNotifier _notifier;

  Future<int> getSessionMessageArchiveCount(String sessionId) {
    return StorageService.instance.getSessionMessageArchiveCount(sessionId);
  }

  Future<storage_models.SessionMessageArchiveSummary>
      getSessionMessageArchiveSummary(
    String sessionId,
  ) {
    return StorageService.instance.getSessionMessageArchiveSummary(sessionId);
  }

  Future<List<storage_models.SessionArchivedTurnSummary>>
      loadSessionMessageArchiveTurnSummaries(
    String sessionId,
  ) {
    return StorageService.instance.loadSessionArchivedTurnSummaries(sessionId);
  }

  Future<bool> ensureSessionMessageArchiveHydrated(
    String sessionId, {
    bool throwOnError = false,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null ||
        existing.totalMessageCount <= existing.messages.length) {
      return false;
    }
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final expectedMessageCount = _resolveExpectedArchiveMessageCount(
      sessionId,
      existing: existing,
    );
    if (_isArchiveSummaryCompleteForExpectedCount(
      summary,
      expectedMessageCount: expectedMessageCount,
    )) {
      return false;
    }
    if (_notifier.getSession(sessionId) == null ||
        !_notifier._sessionDataKeys.containsKey(sessionId)) {
      await _notifier.loadSessions(
        force: _notifier.getSession(sessionId) == null,
      );
      if (_notifier.getSession(sessionId) == null) {
        return false;
      }
    }

    try {
      await _runArchiveHydrationTask(
        sessionId,
        throwOnError: true,
      );
      return true;
    } catch (error) {
      Logger.warning(
        'Failed to hydrate full session archive for $sessionId: $error',
      );
      if (throwOnError) {
        rethrow;
      }
      return false;
    }
  }

  Future<bool> shiftSessionMessageArchiveWindowOlder(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null || existing.windowStartIndex <= 0) {
      return false;
    }
    final beforeStartIndex = existing.windowStartIndex;
    final beforeFirstMessageId =
        existing.messages.isEmpty ? null : existing.messages.first.id;
    final beforeLastMessageId =
        existing.messages.isEmpty ? null : existing.messages.last.id;
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    if (summary.messageCount <= 0 ||
        existing.windowStartIndex > summary.messageCount) {
      return false;
    }
    final pageSize = existing.windowStartIndex > shiftSize
        ? shiftSize
        : existing.windowStartIndex;
    if (pageSize <= 0) {
      return false;
    }
    final pageStartIndex = existing.windowStartIndex - pageSize;
    final olderMessages = await _loadArchiveRange(
      sessionId,
      startIndex: pageStartIndex,
      limit: pageSize,
      expectedTotalCount: summary.messageCount,
    );
    if (olderMessages.isEmpty) {
      return false;
    }
    _notifier._repository.prependMessageWindow(
      sessionId,
      olderMessages,
      totalMessageCount: _resolveWindowTotalMessageCount(
        existing.totalMessageCount,
        summary.messageCount,
        pageStartIndex + olderMessages.length,
      ),
      maxWindowSize: residentWindowSize,
    );
    final updated = _notifier._repository.getSessionMessages(sessionId);
    final effectiveAdvance = updated != null &&
        (updated.windowStartIndex != beforeStartIndex ||
            (updated.messages.isEmpty ? null : updated.messages.first.id) !=
                beforeFirstMessageId ||
            (updated.messages.isEmpty ? null : updated.messages.last.id) !=
                beforeLastMessageId);
    if (!effectiveAdvance) {
      Logger.warning(
        'Prepended archive page did not advance resident window: $sessionId '
        '(requestedStart=$pageStartIndex, loaded=${olderMessages.length}, '
        'resident=$residentWindowSize, start=$beforeStartIndex)',
      );
      return false;
    }
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Prepended archived page for session: $sessionId '
      '(start=$pageStartIndex, loaded=${olderMessages.length}, '
      'resident=${residentWindowSize})',
    );
    return true;
  }

  Future<bool> shiftSessionMessageArchiveWindowNewer(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
    int shiftSize = SessionServiceNotifier.sessionDetailArchiveWindowShiftSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    if (existing == null || existing.hasNewerMessages != true) {
      return false;
    }
    final beforeStartIndex = existing.windowStartIndex;
    final beforeFirstMessageId =
        existing.messages.isEmpty ? null : existing.messages.first.id;
    final beforeLastMessageId =
        existing.messages.isEmpty ? null : existing.messages.last.id;
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final currentWindowEnd =
        existing.windowStartIndex + existing.messages.length;
    if (summary.messageCount <= currentWindowEnd) {
      return false;
    }
    final remaining = summary.messageCount - currentWindowEnd;
    final pageSize = remaining > shiftSize ? shiftSize : remaining;
    if (pageSize <= 0) {
      return false;
    }
    final newerMessages = await _loadArchiveRange(
      sessionId,
      startIndex: currentWindowEnd,
      limit: pageSize,
      expectedTotalCount: summary.messageCount,
    );
    if (newerMessages.isEmpty) {
      return false;
    }
    _notifier._repository.appendMessageWindow(
      sessionId,
      newerMessages,
      totalMessageCount: _resolveWindowTotalMessageCount(
        existing.totalMessageCount,
        summary.messageCount,
        currentWindowEnd + newerMessages.length,
      ),
      maxWindowSize: residentWindowSize,
    );
    final updated = _notifier._repository.getSessionMessages(sessionId);
    final effectiveAdvance = updated != null &&
        (updated.windowStartIndex != beforeStartIndex ||
            (updated.messages.isEmpty ? null : updated.messages.first.id) !=
                beforeFirstMessageId ||
            (updated.messages.isEmpty ? null : updated.messages.last.id) !=
                beforeLastMessageId);
    if (!effectiveAdvance) {
      Logger.warning(
        'Appended archive page did not advance resident window: $sessionId '
        '(requestedStart=$currentWindowEnd, loaded=${newerMessages.length}, '
        'resident=$residentWindowSize, start=$beforeStartIndex)',
      );
      return false;
    }
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Appended archived page for session: $sessionId '
      '(start=$currentWindowEnd, loaded=${newerMessages.length}, '
      'resident=${residentWindowSize})',
    );
    return true;
  }

  Future<bool> loadEarliestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: 0,
      limit: residentWindowSize,
      fallbackTotalCount: existing?.totalMessageCount,
    );
  }

  Future<bool> loadLatestSessionMessageArchiveWindow(
    String sessionId, {
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final existing = _notifier._repository.getSessionMessages(sessionId);
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final totalMessageCount = summary.messageCount > 0
        ? summary.messageCount
        : (existing?.totalMessageCount ?? 0);
    if (totalMessageCount <= 0) {
      return false;
    }
    final startIndex = totalMessageCount > residentWindowSize
        ? totalMessageCount - residentWindowSize
        : 0;
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: startIndex,
      limit: residentWindowSize,
      fallbackTotalCount: totalMessageCount,
    );
  }

  Future<bool> loadSessionMessageArchiveWindowAround(
    String sessionId, {
    required int anchorArchiveIndex,
    int residentWindowSize =
        SessionServiceNotifier.sessionDetailResidentMessageWindowSize,
  }) async {
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final totalMessageCount = summary.messageCount;
    if (totalMessageCount <= 0) {
      return false;
    }
    final clampedAnchor = anchorArchiveIndex.clamp(0, totalMessageCount - 1);
    final halfWindow = residentWindowSize ~/ 2;
    var startIndex = clampedAnchor - halfWindow;
    if (startIndex < 0) {
      startIndex = 0;
    }
    final maxStartIndex = totalMessageCount > residentWindowSize
        ? totalMessageCount - residentWindowSize
        : 0;
    if (startIndex > maxStartIndex) {
      startIndex = maxStartIndex;
    }
    return _loadSessionMessageArchiveWindow(
      sessionId,
      startIndex: startIndex,
      limit: residentWindowSize,
      fallbackTotalCount: totalMessageCount,
    );
  }

  Future<bool> _loadSessionMessageArchiveWindow(
    String sessionId, {
    required int startIndex,
    required int limit,
    int? fallbackTotalCount,
    bool allowRepair = true,
  }) async {
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    var archivedMessages =
        await StorageService.instance.loadSessionMessageArchiveRange(
      sessionId,
      startIndex: startIndex,
      limit: limit,
    );
    if (archivedMessages.isEmpty &&
        summary.messageCount > 0 &&
        await _recoverCorruptedSessionArchive(
          sessionId,
          expectedMessageCount: summary.messageCount,
        )) {
      archivedMessages =
          await StorageService.instance.loadSessionMessageArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
      );
    }
    if (archivedMessages.isEmpty) {
      return false;
    }
    final refreshedSummary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    var totalMessageCount = fallbackTotalCount ?? archivedMessages.length;
    if (refreshedSummary.messageCount > totalMessageCount) {
      totalMessageCount = refreshedSummary.messageCount;
    }
    final availableCount = totalMessageCount > 0
        ? totalMessageCount
        : refreshedSummary.messageCount;
    final expectedLoadedCount = availableCount <= startIndex
        ? 0
        : ((startIndex + limit) > availableCount
            ? availableCount - startIndex
            : limit);
    if (allowRepair &&
        refreshedSummary.isComplete &&
        expectedLoadedCount > 0 &&
        archivedMessages.length < expectedLoadedCount) {
      Logger.warning(
        'Archived window was shorter than expected; repairing session archive: '
        '$sessionId (start=$startIndex, expected=$expectedLoadedCount, '
        'actual=${archivedMessages.length}, total=$availableCount)',
      );
      final repaired = await _recoverCorruptedSessionArchive(
        sessionId,
        expectedMessageCount: availableCount,
      );
      if (!repaired) {
        return false;
      }
      return _loadSessionMessageArchiveWindow(
        sessionId,
        startIndex: startIndex,
        limit: limit,
        fallbackTotalCount: fallbackTotalCount,
        allowRepair: false,
      );
    }
    final loadedUpperBound = startIndex + archivedMessages.length;
    if (loadedUpperBound > totalMessageCount) {
      totalMessageCount = loadedUpperBound;
    }
    _notifier._repository.replaceMessageWindow(
      sessionId,
      archivedMessages,
      totalMessageCount: totalMessageCount,
      windowStartIndex: startIndex,
    );
    await _notifier._persistSessionCacheImmediately(sessionId);
    Logger.info(
      'Loaded archived session message window: $sessionId '
      '(start=$startIndex, loaded=${archivedMessages.length}, total=$totalMessageCount)',
    );
    return true;
  }

  Future<List<ReducerMessage>> _loadArchiveRange(
    String sessionId, {
    required int startIndex,
    required int limit,
    required int expectedTotalCount,
    bool allowRepair = true,
  }) async {
    final summary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    var archivedMessages =
        await StorageService.instance.loadSessionMessageArchiveRange(
      sessionId,
      startIndex: startIndex,
      limit: limit,
    );
    if (archivedMessages.isEmpty &&
        summary.messageCount > 0 &&
        await _recoverCorruptedSessionArchive(
          sessionId,
          expectedMessageCount: expectedTotalCount > 0
              ? expectedTotalCount
              : summary.messageCount,
        )) {
      archivedMessages =
          await StorageService.instance.loadSessionMessageArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
      );
    }
    if (archivedMessages.isEmpty) {
      return const <ReducerMessage>[];
    }
    final refreshedSummary = await StorageService.instance
        .getSessionMessageArchiveSummary(sessionId);
    final availableCount = _resolveWindowTotalMessageCount(
      expectedTotalCount,
      refreshedSummary.messageCount,
      startIndex + archivedMessages.length,
    );
    final expectedLoadedCount = availableCount <= startIndex
        ? 0
        : ((startIndex + limit) > availableCount
            ? availableCount - startIndex
            : limit);
    if (allowRepair &&
        refreshedSummary.isComplete &&
        expectedLoadedCount > 0 &&
        archivedMessages.length < expectedLoadedCount) {
      Logger.warning(
        'Archived page was shorter than expected; repairing session archive: '
        '$sessionId (start=$startIndex, expected=$expectedLoadedCount, '
        'actual=${archivedMessages.length}, total=$availableCount)',
      );
      final repaired = await _recoverCorruptedSessionArchive(
        sessionId,
        expectedMessageCount: availableCount,
      );
      if (!repaired) {
        return const <ReducerMessage>[];
      }
      return _loadArchiveRange(
        sessionId,
        startIndex: startIndex,
        limit: limit,
        expectedTotalCount: expectedTotalCount,
        allowRepair: false,
      );
    }
    return archivedMessages;
  }

  Future<bool> _recoverCorruptedSessionArchive(
    String sessionId, {
    required int expectedMessageCount,
  }) async {
    Logger.warning(
      'Session archive window was unavailable despite non-empty summary: '
      '$sessionId (expected=$expectedMessageCount)',
    );
    if (_notifier.getSession(sessionId) == null) {
      await StorageService.instance.saveSessionMessageArchiveSummary(
        sessionId,
        messageCount: expectedMessageCount,
        isComplete: false,
        lastRemoteSeq: 0,
      );
      return false;
    }
    await StorageService.instance.clearSessionMessageArchive(sessionId);
    await syncFullSessionMessagesFromRemote(
      sessionId,
      throwOnError: true,
    );
    return true;
  }

  Future<void> syncFullSessionMessagesFromRemote(
    String sessionId, {
    bool throwOnError = false,
  }) async {
    try {
      await _runArchiveHydrationTask(
        sessionId,
        throwOnError: true,
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
    final task = _syncFullSessionMessagesFromRemoteInternal(sessionId);
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
    String sessionId,
  ) async {
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
    if (_isArchiveSummaryCompleteForExpectedCount(
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
            'limit': archiveSyncPageSize,
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
          i += archiveSyncParseConcurrency) {
        final chunk = messageItems.sublist(
          i,
          i + archiveSyncParseConcurrency > messageItems.length
              ? messageItems.length
              : i + archiveSyncParseConcurrency,
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
          messageItems.length >= archiveSyncPageSize &&
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

  int _resolveExpectedArchiveMessageCount(
    String sessionId, {
    SessionMessages? existing,
  }) {
    var expectedMessageCount = existing?.totalMessageCount ?? 0;
    final session = _notifier.getSession(sessionId);
    if (session != null) {
      final persistedMessageCount = resolvePersistedSessionMessageCount(
            session: session,
            loadedMessageCount:
                expectedMessageCount > 0 ? expectedMessageCount : null,
          ) ??
          0;
      if (persistedMessageCount > expectedMessageCount) {
        expectedMessageCount = persistedMessageCount;
      }
    }
    return expectedMessageCount;
  }

  bool _isArchiveSummaryCompleteForExpectedCount(
    storage_models.SessionMessageArchiveSummary summary, {
    required int expectedMessageCount,
  }) {
    if (!summary.isComplete || summary.messageCount <= 0) {
      return false;
    }
    if (expectedMessageCount <= 0) {
      return true;
    }
    return summary.messageCount >= expectedMessageCount;
  }

  int _resolveWindowTotalMessageCount(
    int existingTotalCount,
    int archivedCount,
    int loadedUpperBound,
  ) {
    var totalMessageCount = existingTotalCount;
    if (archivedCount > totalMessageCount) {
      totalMessageCount = archivedCount;
    }
    if (loadedUpperBound > totalMessageCount) {
      totalMessageCount = loadedUpperBound;
    }
    return totalMessageCount;
  }

  ReducerMessage _attachArchiveIndex(
    ReducerMessage message,
    int archiveIndex,
  ) {
    final metadata = message.metadata == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(message.metadata!);
    metadata['archiveIndex'] = archiveIndex;
    return message.copyWith(metadata: metadata);
  }
}
