import '../domain/reducer.dart';
import '../domain/session_models.dart';

bool sessionTurnHasCompletionSignal(Iterable<ReducerMessage> messages) {
  for (final message in messages) {
    if (message.isTurnClose) {
      return true;
    }
    if (!message.isAgentEvent) {
      continue;
    }
    final eventType = message.metadata?['eventType']?.toString();
    if (eventType == 'stop' ||
        eventType == 'task_complete' ||
        eventType == 'turn_aborted') {
      return true;
    }
  }
  return false;
}

bool sessionTurnHasPendingToolWork(Iterable<ReducerMessage> messages) {
  for (final message in messages) {
    final status = message.tool?.status;
    if (status == ToolCallStatus.pending ||
        status == ToolCallStatus.approved ||
        status == ToolCallStatus.executing) {
      return true;
    }
  }
  return false;
}

bool sessionTurnHasRenderableAgentOutput(Iterable<ReducerMessage> messages) {
  for (final message in messages) {
    if (message.isToolCall) {
      return true;
    }
    if (!message.isText) {
      continue;
    }
    final role = message.metadata?['role']?.toString();
    final outputType = message.metadata?['outputType']?.toString();
    if (role != 'user' &&
        outputType != 'thinking' &&
        (message.text?.trim().isNotEmpty ?? false)) {
      return true;
    }
  }
  return false;
}

bool sessionTurnIsThinkingStillBlocking({
  required Session? session,
  required Iterable<ReducerMessage> messages,
}) {
  final allMessages = List<ReducerMessage>.from(messages, growable: false);
  if (sessionTurnHasCompletionSignal(allMessages)) {
    return false;
  }
  if (session?.thinking == true) {
    return true;
  }
  for (final message in allMessages.reversed) {
    if (!message.isText) {
      continue;
    }
    if (message.metadata?['role']?.toString() == 'user') {
      continue;
    }
    return message.metadata?['outputType']?.toString() == 'thinking';
  }
  return false;
}

bool sessionActiveResponseHasCompleted({
  required Session? session,
  required Iterable<ReducerMessage> messages,
  required ReducerMessage? userPrompt,
  required bool isSending,
}) {
  if (isSending) {
    return false;
  }
  if (userPrompt?.metadata?['optimistic'] == true) {
    return false;
  }

  final allMessages = List<ReducerMessage>.from(messages, growable: false);
  final hasPendingToolWork = sessionTurnHasPendingToolWork(allMessages);
  if (sessionTurnHasCompletionSignal(allMessages)) {
    return !hasPendingToolWork;
  }
  if (sessionTurnIsThinkingStillBlocking(
    session: session,
    messages: allMessages,
  )) {
    return false;
  }
  if (hasPendingToolWork) {
    return false;
  }
  return sessionTurnHasRenderableAgentOutput(allMessages);
}

bool sessionConversationIsBusy({
  required Session? session,
  required Iterable<ReducerMessage> latestTurnMessages,
  required ReducerMessage? latestUserPrompt,
  required bool isSending,
  required bool isAutoSendingQueuedMessage,
  required String? activeResponseLocalId,
}) {
  if (isSending || isAutoSendingQueuedMessage) {
    return true;
  }
  if (activeResponseLocalId != null) {
    return true;
  }
  if (sessionTurnIsThinkingStillBlocking(
    session: session,
    messages: latestTurnMessages,
  )) {
    return true;
  }
  if (sessionTurnHasPendingToolWork(latestTurnMessages)) {
    return true;
  }
  if (latestUserPrompt?.metadata?['optimistic'] == true) {
    return true;
  }
  return false;
}
