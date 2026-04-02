part of 'session_repository.dart';

extension SessionRepositoryStateMutations on SessionRepository {
  void _syncSessionLatestUsageWithLoadedCount(
    String sessionId,
    int loadedMessageCount,
  ) {
    final existingSession = _sessions[sessionId];
    if (existingSession == null) {
      return;
    }
    final nextLatestUsage = resolvePersistedSessionLatestUsage(
      session: existingSession,
      loadedMessageCount: loadedMessageCount,
    );
    if (_sessionRepositoryDeepEquality.equals(
      existingSession.latestUsage?.toJson(),
      nextLatestUsage?.toJson(),
    )) {
      return;
    }
    _sessions[sessionId] = existingSession.copyWith(
      latestUsage: nextLatestUsage,
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
      );
    } else {
      _sessionMessages[sessionId] = SessionMessages(
        messages: existing.messages,
        messagesMap: existing.messagesMap,
        reducerState: existing.reducerState,
        isLoaded: existing.isLoaded,
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
    );
    _syncSessionLatestUsageWithLoadedCount(sessionId, 0);
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
    );
    _syncSessionLatestUsageWithLoadedCount(sessionId, nextMessages.length);
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

  SessionMessages({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
    this.isLoaded = false,
  });
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
