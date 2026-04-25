part of 'session_service.dart';

class _SessionServiceMessageCoordinator {
  static const int sessionMessagesPageSize = 100;
  static const int sessionCacheParseIsolateThreshold = 40;

  const _SessionServiceMessageCoordinator(this._notifier);

  final SessionServiceNotifier _notifier;

  Future<void> loadSessionMessages(
    String sessionId, {
    bool force = false,
    bool throwOnError = false,
    bool preserveOptimisticMessages = true,
    int? maxPages,
    int? messageWindowSize,
  }) async {
    // Serialize per-session message loads.
    // Non-force loads join the in-flight request directly.
    // Force loads wait for the current request to finish, then run with
    // fresh state, preventing concurrent overwrites of the same session
    // message window from competing refresh sources.
    final inFlight = _notifier._loadMessagesInFlight[sessionId];
    if (inFlight != null) {
      if (!force) {
        return inFlight;
      }
      await inFlight;
    }
    final completer = Completer<void>();
    _notifier._loadMessagesInFlight[sessionId] = completer.future;
    try {
      final sessionKey = _notifier._sessionDataKeys[sessionId];
      final existing = _notifier._repository.getSessionMessages(sessionId);
      final effectiveMessageWindowSize = _resolveEffectiveMessageWindowSize(
        existing,
        requestedWindowSize: messageWindowSize,
      );
      if (!force && maxPages == null && existing?.hasNewerMessages == true) {
        Logger.info(
          'Skipping incremental message refresh for archived window: $sessionId '
          '(start=${existing!.windowStartIndex}, loaded=${existing.messages.length}, '
          'total=${existing.totalMessageCount})',
        );
        return;
      }
      final previousCount = existing?.messages.length ?? 0;
      final previousTotalCount = existing?.totalMessageCount ?? previousCount;
      var afterSeq = force
          ? 0
          : (existing == null
              ? 0
              : (_notifier._sessionLastSeq[sessionId] ?? 0));
      var hasMore = true;
      var loadedPages = 0;
      final pageLimit = maxPages == null || maxPages <= 0 ? null : maxPages;
      final retainedMessages = <ReducerMessage>[];
      final retainedMessageWindow = effectiveMessageWindowSize == null
          ? null
          : ListQueue<ReducerMessage>();
      var totalFetchedMessageCount =
          force || afterSeq == 0 ? 0 : previousTotalCount;

      while (hasMore) {
        final response = await _notifier._requestSessionMessages<dynamic>(
          sessionId: sessionId,
          action: (path) => ApiService.instance.get<dynamic>(
            path,
            queryParameters: {
              'after_seq': afterSeq,
              'limit': sessionMessagesPageSize,
            },
            options: Options(receiveTimeout: const Duration(seconds: 90)),
          ),
        );
        final messageItems = _notifier._extractListPayload(
          response,
          'messages',
          fallbackKeys: const ['items', 'data', 'results'],
        );
        final responseMap = _notifier._asStringMap(response);
        var maxSeq = afterSeq;

        const parseConcurrency = 15;
        final batchResults = <(int?, List<ReducerMessage>)>[];
        for (var i = 0; i < messageItems.length; i += parseConcurrency) {
          final chunk = messageItems.sublist(
            i,
            i + parseConcurrency > messageItems.length
                ? messageItems.length
                : i + parseConcurrency,
          );
          final chunkResults = await Future.wait(
            chunk.map((item) async {
              final messageJson = _notifier._asStringMap(item);
              if (messageJson == null) return null;
              final seq = _notifier._parseSeq(messageJson['seq']);
              try {
                final parsedMessages = await _notifier._parseServerMessages(
                  messageJson,
                  sessionKey: sessionKey,
                  secretKey: _notifier._accountSecret,
                );
                return (seq, parsedMessages);
              } catch (error) {
                Logger.warning('Failed to parse message: $error');
                return null;
              }
            }),
          );
          for (final result in chunkResults) {
            if (result == null) continue;
            batchResults.add(result);
          }
        }
        for (final result in batchResults) {
          final (seq, parsedMessages) = result;
          if (seq != null && seq > maxSeq) {
            maxSeq = seq;
          }
          totalFetchedMessageCount += parsedMessages.length;
          if (retainedMessageWindow == null) {
            retainedMessages.addAll(parsedMessages);
            continue;
          }
          for (final message in parsedMessages) {
            retainedMessageWindow.addLast(message);
            if (retainedMessageWindow.length > effectiveMessageWindowSize!) {
              retainedMessageWindow.removeFirst();
            }
          }
        }

        final responseHasMore =
            responseMap?['hasMore'] == true || responseMap?['has_more'] == true;
        final inferredHasMore = !responseHasMore &&
            messageItems.length >= sessionMessagesPageSize &&
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

      final rawMessageList = retainedMessageWindow == null
          ? List<ReducerMessage>.unmodifiable(retainedMessages)
          : List<ReducerMessage>.unmodifiable(
              retainedMessageWindow.toList(growable: false),
            );
      final nestedMessageList =
          _notifier._nestSidechainMessages(rawMessageList);
      final retainedMessageList =
          _notifier._resolveHistoricalToolCallStatuses(nestedMessageList);
      _notifier._sessionLastSeq[sessionId] = afterSeq;
      if (force) {
        if (retainedMessageList.isEmpty &&
            existing != null &&
            existing.messages.isNotEmpty) {
          Logger.warning(
            'Session messages force-reload produced empty result for $sessionId; '
            'keeping ${existing.messages.length} existing messages to avoid data loss',
          );
        } else {
          _notifier._repository.replaceMessages(
            sessionId,
            retainedMessageList,
            preserveOptimisticMessages: preserveOptimisticMessages,
            totalMessageCount: totalFetchedMessageCount,
            messageWindowSize: effectiveMessageWindowSize,
          );
        }
      } else if (retainedMessageList.isNotEmpty ||
          existing == null ||
          existing.isLoaded == false) {
        _notifier._repository.applyMessages(
          sessionId,
          retainedMessageList,
          totalMessageCount: totalFetchedMessageCount,
          messageWindowSize: effectiveMessageWindowSize,
        );
      }
      final refreshedMessages = _notifier._repository.getSessionMessages(
        sessionId,
      );
      final refreshedCount = refreshedMessages?.messages.length ?? 0;
      final refreshedTotalCount =
          refreshedMessages?.totalMessageCount ?? totalFetchedMessageCount;
      Logger.info(
        force
            ? 'Session messages reloaded: $sessionId '
                '(server=$totalFetchedMessageCount, retained=${retainedMessageList.length}, '
                'local=$previousCount->$refreshedCount, total=$refreshedTotalCount, '
                'pages=$loadedPages, window=${effectiveMessageWindowSize ?? "full"})'
            : 'Session messages loaded: $sessionId '
                '(server=$totalFetchedMessageCount, retained=${retainedMessageList.length}, '
                'local=$previousCount->$refreshedCount, total=$refreshedTotalCount, '
                'pages=$loadedPages, window=${effectiveMessageWindowSize ?? "full"})',
      );
    } catch (error) {
      Logger.error('Load session messages error for $sessionId: $error');
      if (throwOnError) {
        rethrow;
      }
    } finally {
      if (identical(
          _notifier._loadMessagesInFlight[sessionId], completer.future)) {
        _notifier._loadMessagesInFlight.remove(sessionId);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  int? _resolveEffectiveMessageWindowSize(
    SessionMessages? existing, {
    required int? requestedWindowSize,
  }) {
    if (requestedWindowSize == null || existing == null) {
      return requestedWindowSize;
    }
    final loadedCount = existing.messages.length;
    final browsingExpandedResidentWindow = loadedCount > requestedWindowSize &&
        existing.isLoaded &&
        (existing.hasOlderMessages || existing.hasNewerMessages);
    if (!browsingExpandedResidentWindow) {
      return requestedWindowSize;
    }
    return loadedCount;
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
      await _notifier._persistSessionCacheImmediately(sessionId);
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
            final existing =
                _notifier._repository.getSessionMessages(sessionId);
            final isPreviewRefresh =
                !force && maxPagesPerSession != null && maxPagesPerSession > 0;
            if (isPreviewRefresh && existing?.isLoaded != true) {
              Logger.info(
                'Loading initial messages for unloaded session: $sessionId',
              );
              return loadSessionMessages(
                sessionId,
                force: false,
                throwOnError: true,
                maxPages: maxPagesPerSession,
              );
            }
            final shouldLimitPages = !force &&
                maxPagesPerSession != null &&
                maxPagesPerSession > 0 &&
                existing?.isLoaded == true;
            final previewWindowSize = shouldLimitPages &&
                    existing != null &&
                    existing.messages.isNotEmpty
                ? existing.messages.length
                : null;
            return loadSessionMessages(
              sessionId,
              force: force,
              throwOnError: true,
              maxPages: shouldLimitPages ? maxPagesPerSession : null,
              messageWindowSize: previewWindowSize,
            );
          }(),
      ]);
    }
  }
}
