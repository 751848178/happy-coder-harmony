part of 'session_repository.dart';

extension SessionRepositoryStateMutations on SessionRepository {
  void _syncSessionPreviewFieldsFromMessages(
    String sessionId,
    int loadedMessageCount,
  ) {
    final existingSession = _sessions[sessionId];
    if (existingSession == null) {
      return;
    }
    final sessionMessages = _sessionMessages[sessionId];
    final effectiveMessageCount =
        sessionMessages?.totalMessageCount ?? loadedMessageCount;
    final nextLatestUsage = resolvePersistedSessionLatestUsage(
      session: existingSession,
      loadedMessageCount: effectiveMessageCount,
    );
    final messages = sessionMessages?.messages;
    final previewWindowIsLatest = sessionMessages?.hasNewerMessages != true;
    final nextPreviewText = previewWindowIsLatest && messages != null
        ? resolveLatestMessagePreview(messages)
        : existingSession.previewText;
    final nextLastMessageAt = previewWindowIsLatest && messages != null
        ? resolveLatestMessageAt(messages)
        : existingSession.lastMessageAt;
    final nextListStatusKind = previewWindowIsLatest && messages != null
        ? resolveLatestSessionStatusKind(messages)?.name
        : existingSession.listStatusKind;
    if (_sessionRepositoryDeepEquality.equals(
          existingSession.latestUsage?.toJson(),
          nextLatestUsage?.toJson(),
        ) &&
        existingSession.previewText == nextPreviewText &&
        existingSession.lastMessageAt == nextLastMessageAt &&
        existingSession.listStatusKind == nextListStatusKind) {
      return;
    }
    _sessions[sessionId] = existingSession.copyWith(
      latestUsage: nextLatestUsage,
      previewText: nextPreviewText,
      lastMessageAt: nextLastMessageAt,
      listStatusKind: nextListStatusKind,
    );
    Logger.info(
      '[SessionPreview] updated session=$sessionId '
      'messages=$effectiveMessageCount loaded=$loadedMessageCount '
      'hasPreview=${nextPreviewText != null || nextLastMessageAt != null} '
      'status=${nextListStatusKind ?? "none"} '
      'lastAt=${nextLastMessageAt?.toIso8601String() ?? "null"}',
    );
  }

  void approveToolCall(String sessionId, String toolId) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) return;

    final updatedMessages = <domain.ReducerMessage>[];
    for (final message in existing.messages) {
      if (message.tool != null && message.tool!.id == toolId) {
        updatedMessages.add(
          message.copyWith(
            tool: message.tool!.copyWith(
              status: domain.ToolCallStatus.approved,
            ),
          ),
        );
      } else {
        updatedMessages.add(message);
      }
    }
    _replaceToolState(
        sessionId, toolId, updatedMessages, SessionChangeType.toolCallApproved);
  }

  void rejectToolCall(String sessionId, String toolId, {String? reason}) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) return;

    final updatedMessages = <domain.ReducerMessage>[];
    for (final message in existing.messages) {
      if (message.tool != null && message.tool!.id == toolId) {
        updatedMessages.add(
          message.copyWith(
            tool: message.tool!.copyWith(
              status: domain.ToolCallStatus.rejected,
              error: reason ?? 'Rejected by user',
            ),
          ),
        );
      } else {
        updatedMessages.add(message);
      }
    }
    _replaceToolState(
        sessionId, toolId, updatedMessages, SessionChangeType.toolCallRejected);
  }

  void _replaceToolState(
    String sessionId,
    String toolId,
    List<domain.ReducerMessage> messages,
    SessionChangeType type,
  ) {
    final existing = _sessionMessages[sessionId]!;
    final updatedMessagesMap = {
      for (final message in messages) message.id: message,
    };

    _sessionMessages[sessionId] = SessionMessages.resolved(
      messages: messages,
      messagesMap: updatedMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
      totalMessageCount: existing.totalMessageCount,
      windowStartIndex: existing.windowStartIndex,
    );

    _stateController.add(
      SessionStateChange(
        type: type,
        sessionId: sessionId,
        toolId: toolId,
      ),
    );
  }

  void clearSessionMessages(String sessionId) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) {
      return;
    }
    _sessionMessages[sessionId] = SessionMessages(
      messages: const [],
      messagesMap: const {},
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
      totalMessageCount: 0,
      windowStartIndex: 0,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, 0);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info('Cleared messages for session: $sessionId');
  }

  void removeMessage(String sessionId, String messageId) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) {
      return;
    }
    final nextMessagesMap = Map<String, domain.ReducerMessage>.from(
      existing.messagesMap,
    );
    var removed = nextMessagesMap.remove(messageId) != null;
    if (!removed) {
      final optimisticMessageId =
          _findMessageIdByLocalId(nextMessagesMap, messageId);
      if (optimisticMessageId != null) {
        nextMessagesMap.remove(optimisticMessageId);
        removed = true;
      }
    }
    if (!removed) {
      return;
    }
    final nextMessages = nextMessagesMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: existing.isLoaded,
      totalMessageCount: existing.totalMessageCount > 0
          ? existing.totalMessageCount - 1
          : nextMessages.length,
      windowStartIndex: existing.windowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
  }

  Map<String, SessionMessages> get sessionMessagesMap =>
      UnmodifiableMapView(_sessionMessages);
}
