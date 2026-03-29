import '../domain/reducer.dart';
import '../domain/session_models.dart';

bool sessionMessageIsUserAuthored(ReducerMessage message) {
  final metadata = message.metadata;
  final role = metadata?['role']?.toString();
  final sourceRole = metadata?['sourceRole']?.toString();
  return role == 'user' || sourceRole == 'user';
}

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
        eventType == 'ready' ||
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
    final outputType = message.metadata?['outputType']?.toString();
    if (!sessionMessageIsUserAuthored(message) &&
        outputType != 'thinking' &&
        (message.text?.trim().isNotEmpty ?? false)) {
      return true;
    }
  }
  return false;
}

/// 判断思考状态是否超时（用于检测会话中断的情况）
/// 如果会话思考时间超过阈值，认为可能已中断
bool _isThinkingTimedOut(Session? session) {
  if (session == null) {
    return false;
  }
  final thinking = session.thinking;
  final thinkingAt = session.thinkingAt;
  if (thinking != true || thinkingAt == null) {
    return false;
  }
  // 如果思考时间超过 2 分钟，认为可能已中断
  const timeoutDuration = Duration(minutes: 2);
  final elapsed = DateTime.now().difference(thinkingAt);
  return elapsed >= timeoutDuration;
}

bool sessionTurnIsThinkingStillBlocking({
  required Session? session,
  required Iterable<ReducerMessage> messages,
  bool? manualThinkingOverride,
}) {
  if (manualThinkingOverride != null) {
    return manualThinkingOverride;
  }
  final allMessages = List<ReducerMessage>.from(messages, growable: false);
  if (sessionTurnHasCompletionSignal(allMessages)) {
    return false;
  }
  if (session?.thinking == true) {
    // 修复会话中断后思考状态无法清除的问题：
    // 如果会话思考时间超过阈值（如 2 分钟），认为可能已中断，不应阻塞新消息
    if (_isThinkingTimedOut(session)) {
      return false;
    }
    return true;
  }
  for (final message in allMessages.reversed) {
    if (!message.isText) {
      continue;
    }
    if (sessionMessageIsUserAuthored(message)) {
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
  bool? manualThinkingOverride,
}) {
  if (isSending || isAutoSendingQueuedMessage) {
    return true;
  }
  if (manualThinkingOverride == false) {
    return false;
  }
  if (activeResponseLocalId != null) {
    return true;
  }
  if (sessionTurnIsThinkingStillBlocking(
    session: session,
    messages: latestTurnMessages,
    manualThinkingOverride: manualThinkingOverride,
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
