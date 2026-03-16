part of 'session_repository.dart';

extension SessionRepositoryMessages on SessionRepository {
  SessionMessages? getSessionMessages(String sessionId) {
    return _sessionMessages[sessionId];
  }

  void applyMessages(String sessionId, List<domain.ReducerMessage> messages) {
    final existing = _sessionMessages[sessionId];

    if (existing == null) {
      final messagesMap = <String, domain.ReducerMessage>{};
      for (final message in messages) {
        messagesMap[message.id] = message;
      }
      _sessionMessages[sessionId] = SessionMessages(
        messages: messages,
        messagesMap: messagesMap,
        reducerState: domain.ReducerState.initial,
        isLoaded: true,
      );
    } else {
      final mergedMessagesMap = Map<String, domain.ReducerMessage>.from(
        existing.messagesMap,
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

      final messagesArray = mergedMessagesMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _sessionMessages[sessionId] = SessionMessages(
        messages: messagesArray,
        messagesMap: mergedMessagesMap,
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
      );
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

    final nextMessages = nextMessagesMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing?.reducerState ?? domain.ReducerState.initial,
      isLoaded: true,
    );
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
}
