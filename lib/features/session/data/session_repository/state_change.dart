part of 'session_repository.dart';

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
