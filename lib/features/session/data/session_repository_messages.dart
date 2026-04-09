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

    if (existing == null) {
      final trimmedMessages = _trimMessageWindow(messages, messageWindowSize);
      final messagesMap = _buildMessagesMap(trimmedMessages);
      _sessionMessages[sessionId] = SessionMessages(
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
      for (var i = 0; i < messages.length; i++) {
        if (existingMap.containsKey(messages[i].id)) {
          allNew = false;
          break;
        }
      }

      List<domain.ReducerMessage> messagesArray;
      Map<String, domain.ReducerMessage> mergedMessagesMap;

      if (allNew && messages.isNotEmpty) {
        // No overlap — just append. No need to copy existing map or re-sort
        // (incoming messages are already sorted by createdAt).
        mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
          existingMap,
        );
        for (final message in messages) {
          mergedMessagesMap[message.id] = message;
        }
        messagesArray = <domain.ReducerMessage>[
          ...existing.messages,
          ...messages,
        ];
      } else {
        // General path: merge with dedup and re-sort.
        mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
          existingMap,
        );
        for (final message in messages) {
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

      _sessionMessages[sessionId] = SessionMessages(
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

    for (final message in messages) {
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
      '(${messages.length} server messages)',
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

  void prependMessageWindow(
    String sessionId,
    List<domain.ReducerMessage> olderMessages, {
    required int totalMessageCount,
    required int maxWindowSize,
  }) {
    final existing = _sessionMessages[sessionId];
    if (existing == null || olderMessages.isEmpty) {
      return;
    }

    final mergedMessages = _canonicalizeMessageWindow(<domain.ReducerMessage>[
      ...olderMessages,
      ...existing.messages,
    ]);
    var nextWindowStartIndex = existing.windowStartIndex - olderMessages.length;
    if (nextWindowStartIndex < 0) {
      nextWindowStartIndex = 0;
    }
    var nextMessages = mergedMessages;
    if (maxWindowSize > 0 && nextMessages.length > maxWindowSize) {
      nextMessages = List<domain.ReducerMessage>.unmodifiable(
        nextMessages.sublist(0, maxWindowSize),
      );
    }
    nextWindowStartIndex = _resolveWindowStartIndexFromMessages(
      nextMessages,
      fallback: nextWindowStartIndex,
    );
    final nextMessagesMap = _buildMessagesMap(nextMessages);
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: true,
      totalMessageCount: totalMessageCount,
      windowStartIndex: nextWindowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Prepended message window for session: $sessionId '
      '(prepended=${olderMessages.length}, loaded=${nextMessages.length}, '
      'total=$totalMessageCount, start=$nextWindowStartIndex)',
    );
  }

  void appendMessageWindow(
    String sessionId,
    List<domain.ReducerMessage> newerMessages, {
    required int totalMessageCount,
    required int maxWindowSize,
  }) {
    final existing = _sessionMessages[sessionId];
    if (existing == null || newerMessages.isEmpty) {
      return;
    }

    final mergedMessages = _canonicalizeMessageWindow(<domain.ReducerMessage>[
      ...existing.messages,
      ...newerMessages,
    ]);
    var nextWindowStartIndex = existing.windowStartIndex;
    var nextMessages = mergedMessages;
    if (maxWindowSize > 0 && nextMessages.length > maxWindowSize) {
      final trimFromStart = nextMessages.length - maxWindowSize;
      nextMessages = List<domain.ReducerMessage>.unmodifiable(
        nextMessages.sublist(trimFromStart),
      );
      nextWindowStartIndex += trimFromStart;
    }
    nextWindowStartIndex = _resolveWindowStartIndexFromMessages(
      nextMessages,
      fallback: nextWindowStartIndex,
    );
    final nextMessagesMap = _buildMessagesMap(nextMessages);
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: true,
      totalMessageCount: totalMessageCount,
      windowStartIndex: nextWindowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Appended message window for session: $sessionId '
      '(appended=${newerMessages.length}, loaded=${nextMessages.length}, '
      'total=$totalMessageCount, start=$nextWindowStartIndex)',
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
