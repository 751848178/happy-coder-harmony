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

  void applyAgentState(String sessionId, Map<String, dynamic>? agentState) {
    final existing = _sessionMessages[sessionId];
    if (existing == null) {
      _sessionMessages[sessionId] = SessionMessages(
        messages: const [],
        messagesMap: const {},
        reducerState: domain.ReducerState.initial,
        isLoaded: true,
        totalMessageCount: 0,
        windowStartIndex: 0,
      );
    } else {
      _sessionMessages[sessionId] = SessionMessages(
        messages: existing.messages,
        messagesMap: existing.messagesMap,
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
        totalMessageCount: existing.totalMessageCount,
        windowStartIndex: existing.windowStartIndex,
      );
    }
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.agentStateUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info('Applied agent state to session: $sessionId');
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

    _sessionMessages[sessionId] = SessionMessages(
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

class SessionMessages {
  final List<domain.ReducerMessage> messages;
  final Map<String, domain.ReducerMessage> messagesMap;
  final domain.ReducerState reducerState;
  final bool isLoaded;
  final int totalMessageCount;
  final int windowStartIndex;
  final bool hasOlderMessages;
  final bool hasNewerMessages;

  SessionMessages({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
    this.isLoaded = false,
    int? totalMessageCount,
    int? windowStartIndex,
  })  : totalMessageCount = totalMessageCount ?? messages.length,
        windowStartIndex = windowStartIndex ??
            _resolveLatestWindowStartIndex(
              totalMessageCount: totalMessageCount ?? messages.length,
              loadedMessageCount: messages.length,
            ),
        hasOlderMessages = (windowStartIndex ??
                _resolveLatestWindowStartIndex(
                  totalMessageCount: totalMessageCount ?? messages.length,
                  loadedMessageCount: messages.length,
                )) >
            0,
        hasNewerMessages = _resolveHasNewerMessages(
          messages: messages,
          totalMessageCount: totalMessageCount ?? messages.length,
          windowStartIndex: windowStartIndex,
        );
}

int _resolveLatestWindowStartIndex({
  required int totalMessageCount,
  required int loadedMessageCount,
}) {
  final startIndex = totalMessageCount - loadedMessageCount;
  return startIndex > 0 ? startIndex : 0;
}

bool _resolveHasNewerMessages({
  required List<domain.ReducerMessage> messages,
  required int totalMessageCount,
  required int? windowStartIndex,
}) {
  var maxArchiveIndex = -1;
  for (final message in messages) {
    final rawValue = message.metadata?['archiveIndex'];
    final archiveIndex = rawValue is int
        ? rawValue
        : rawValue is String
            ? int.tryParse(rawValue) ?? -1
            : rawValue is double
                ? rawValue.toInt()
                : -1;
    if (archiveIndex > maxArchiveIndex) {
      maxArchiveIndex = archiveIndex;
    }
  }
  if (maxArchiveIndex >= 0) {
    return (maxArchiveIndex + 1) < totalMessageCount;
  }
  final resolvedWindowStartIndex = windowStartIndex ??
      _resolveLatestWindowStartIndex(
        totalMessageCount: totalMessageCount,
        loadedMessageCount: messages.length,
      );
  return (resolvedWindowStartIndex + messages.length) < totalMessageCount;
}

class SessionStateChange {
  final SessionChangeType type;
  final String? sessionId;
  final String? toolId;

  SessionStateChange({
    required this.type,
    this.sessionId,
    this.toolId,
  });
}

enum SessionChangeType {
  sessionsUpdated,
  messagesUpdated,
  agentStateUpdated,
  toolCallApproved,
  toolCallRejected,
  draftUpdated,
  permissionModeUpdated,
  modelModeUpdated,
  sessionDeleted,
  machinesUpdated,
  cleared,
}
