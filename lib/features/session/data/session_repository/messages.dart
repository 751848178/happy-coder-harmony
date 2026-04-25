part of 'session_repository.dart';

extension SessionRepositoryMessages on SessionRepository {
  SessionMessages? getSessionMessages(String sessionId) {
    return _sessionMessages[sessionId];
  }

  void applyMessages(
    String sessionId,
    List<domain.ReducerMessage> messages, {
    int? totalMessageCount,
    int? messageWindowSize,
    int? windowStartIndex,
  }) {
    final existing = _sessionMessages[sessionId];

    // Canonicalize incoming messages to merge within-batch duplicates
    // (e.g. tool_use + tool_result with the same toolId).  Without this,
    // tool_result messages (which carry name='unknown') overwrite tool_use
    // messages (which have the correct name) when both arrive in one batch.
    final canonicalMessages =
        messages.length > 1 ? _canonicalizeMessageWindow(messages) : messages;

    if (existing == null) {
      final trimmedMessages =
          _trimMessageWindow(canonicalMessages, messageWindowSize);
      final messagesMap = _buildMessagesMap(trimmedMessages);
      _sessionMessages[sessionId] = SessionMessages.resolved(
        messages: trimmedMessages,
        messagesMap: messagesMap,
        reducerState: domain.ReducerState.initial,
        isLoaded: true,
        totalMessageCount: totalMessageCount,
        windowStartIndex: windowStartIndex,
      );
      _syncSessionPreviewFieldsFromMessages(sessionId, trimmedMessages.length);
    } else {
      // Fast path: if all incoming messages are new (no overlap with existing),
      // skip the per-item merge loop and just append.
      final existingMap = existing.messagesMap;
      var allNew = true;
      for (var i = 0; i < canonicalMessages.length; i++) {
        if (existingMap.containsKey(canonicalMessages[i].id)) {
          allNew = false;
          break;
        }
      }

      List<domain.ReducerMessage> messagesArray;
      Map<String, domain.ReducerMessage> mergedMessagesMap;

      if (allNew && canonicalMessages.isNotEmpty) {
        // No overlap — just append. No need to copy existing map or re-sort
        // (incoming messages are already sorted by createdAt).
        // Still need to remove optimistic messages that match by localId,
        // otherwise the optimistic + server message coexist as duplicates.
        mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
          existingMap,
        );
        for (final message in canonicalMessages) {
          final localId = message.metadata?['localId']?.toString();
          if (localId != null && localId.isNotEmpty) {
            final optimisticMessageId =
                _findMessageIdByLocalId(mergedMessagesMap, localId);
            if (optimisticMessageId != null &&
                optimisticMessageId != message.id) {
              mergedMessagesMap.remove(optimisticMessageId);
            }
          }
          mergedMessagesMap[message.id] = message;
        }
        messagesArray = mergedMessagesMap.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        // General path: merge with dedup and re-sort.
        mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
          existingMap,
        );
        for (final message in canonicalMessages) {
          final localId = message.metadata?['localId']?.toString();
          if (localId != null && localId.isNotEmpty) {
            final optimisticMessageId =
                _findMessageIdByLocalId(mergedMessagesMap, localId);
            if (optimisticMessageId != null &&
                optimisticMessageId != message.id) {
              mergedMessagesMap.remove(optimisticMessageId);
            }
          }
          final previous = mergedMessagesMap[message.id];
          mergedMessagesMap[message.id] = _mergeMessage(previous, message);
        }
        messagesArray = mergedMessagesMap.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      messagesArray = _trimMessageWindow(messagesArray, messageWindowSize);
      mergedMessagesMap = _buildMessagesMap(messagesArray);

      _sessionMessages[sessionId] = SessionMessages.resolved(
        messages: messagesArray,
        messagesMap: mergedMessagesMap,
        reducerState: existing.reducerState,
        isLoaded: true,
        totalMessageCount: totalMessageCount ?? messagesArray.length,
        windowStartIndex: windowStartIndex,
      );
      _syncSessionPreviewFieldsFromMessages(sessionId, messagesArray.length);
    }
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info('Applied ${messages.length} messages to session: $sessionId');
  }

  void replaceMessages(
    String sessionId,
    List<domain.ReducerMessage> messages, {
    bool preserveOptimisticMessages = true,
    int? totalMessageCount,
    int? messageWindowSize,
    int? windowStartIndex,
  }) {
    final existing = _sessionMessages[sessionId];
    final existingMessagesMap = existing?.messagesMap;
    final nextMessagesMap = <String, domain.ReducerMessage>{};

    // Canonicalize incoming messages to merge within-batch duplicates
    // (e.g. tool_use + tool_result with the same toolId).
    final canonicalMessages =
        messages.length > 1 ? _canonicalizeMessageWindow(messages) : messages;

    for (final message in canonicalMessages) {
      final previous = _findPreviousMessageForIncoming(
        existingMessagesMap,
        message,
      );
      nextMessagesMap[message.id] = _mergeMessage(previous, message);
    }

    if (preserveOptimisticMessages && existingMessagesMap != null) {
      for (final previous in existingMessagesMap.values) {
        if (!_isOptimisticMessage(previous)) {
          continue;
        }
        final localId =
            previous.metadata?['localId']?.toString() ?? previous.id;
        if (_findMessageIdByLocalId(nextMessagesMap, localId) != null) {
          continue;
        }
        nextMessagesMap[previous.id] = previous;
      }
    }

    var nextMessages = nextMessagesMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    nextMessages = _trimMessageWindow(nextMessages, messageWindowSize);
    final trimmedMessagesMap = _buildMessagesMap(nextMessages);

    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: trimmedMessagesMap,
      reducerState: existing?.reducerState ?? domain.ReducerState.initial,
      isLoaded: true,
      totalMessageCount: totalMessageCount ?? nextMessages.length,
      windowStartIndex: windowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Replaced message snapshot for session: $sessionId '
      '(${canonicalMessages.length} canonical messages)',
    );
  }

  void replaceMessageWindow(
    String sessionId,
    List<domain.ReducerMessage> messages, {
    required int totalMessageCount,
    required int windowStartIndex,
  }) {
    final existing = _sessionMessages[sessionId];
    final nextMessages = _canonicalizeMessageWindow(messages);
    final resolvedWindowStartIndex = _resolveWindowStartIndexFromMessages(
      nextMessages,
      fallback: windowStartIndex,
    );
    final nextMessagesMap = _buildMessagesMap(nextMessages);
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing?.reducerState ?? domain.ReducerState.initial,
      isLoaded: true,
      totalMessageCount: totalMessageCount,
      windowStartIndex: resolvedWindowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Replaced message window for session: $sessionId '
      '(loaded=${nextMessages.length}, total=$totalMessageCount, '
      'start=$resolvedWindowStartIndex)',
    );
  }
}

List<domain.ReducerMessage> _trimMessageWindow(
  List<domain.ReducerMessage> messages,
  int? messageWindowSize,
) {
  if (messageWindowSize == null ||
      messageWindowSize <= 0 ||
      messages.length <= messageWindowSize) {
    return messages;
  }
  return List<domain.ReducerMessage>.unmodifiable(
    messages.sublist(messages.length - messageWindowSize),
  );
}

Map<String, domain.ReducerMessage> _buildMessagesMap(
  List<domain.ReducerMessage> messages,
) {
  return <String, domain.ReducerMessage>{
    for (final message in messages) message.id: message,
  };
}
