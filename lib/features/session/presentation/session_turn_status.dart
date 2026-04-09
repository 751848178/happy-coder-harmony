import '../domain/reducer.dart';
import '../domain/session_models.dart';

class SessionThinkingSnapshot {
  const SessionThinkingSnapshot({
    required this.isThinking,
    this.since,
  });

  final bool isThinking;
  final DateTime? since;
}

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

bool sessionTurnHasBlockingToolWork(Iterable<ReducerMessage> messages) {
  if (sessionTurnHasCompletionSignal(messages)) {
    return false;
  }
  return sessionTurnHasPendingToolWork(messages);
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

DateTime? _resolveThinkingStartedAt(
  Session? session,
  Iterable<ReducerMessage> messages,
) {
  if (session?.thinkingAt != null) {
    return session!.thinkingAt;
  }
  for (final message in (messages is List<ReducerMessage> ? messages : messages.toList(growable: false)).reversed) {
    if (!message.isText || sessionMessageIsUserAuthored(message)) {
      continue;
    }
    if (message.metadata?['outputType']?.toString() == 'thinking') {
      return message.createdAt;
    }
  }
  return null;
}

SessionThinkingSnapshot resolveSessionThinkingSnapshot({
  required Session? session,
  required Iterable<ReducerMessage> messages,
  bool? manualThinkingOverride,
}) {
  final list = messages is List<ReducerMessage>
      ? messages
      : messages.toList(growable: false);
  if (manualThinkingOverride == false) {
    return const SessionThinkingSnapshot(isThinking: false);
  }
  if (manualThinkingOverride == true) {
    if (sessionTurnHasCompletionSignal(list)) {
      return const SessionThinkingSnapshot(isThinking: false);
    }
    return SessionThinkingSnapshot(
      isThinking: true,
      since: _resolveThinkingStartedAt(session, list),
    );
  }
  if (session?.thinking == true) {
    if (sessionTurnHasCompletionSignal(list)) {
      return const SessionThinkingSnapshot(isThinking: false);
    }
    if (_isThinkingTimedOut(session)) {
      return const SessionThinkingSnapshot(isThinking: false);
    }
    return SessionThinkingSnapshot(
      isThinking: true,
      since: _resolveThinkingStartedAt(session, list),
    );
  }
  if (sessionTurnHasCompletionSignal(list)) {
    return const SessionThinkingSnapshot(isThinking: false);
  }
  // Fast path: session is not thinking and no manual override.
  // Only need to check the last non-user text message.
  for (final message in list.reversed) {
    if (!message.isText) {
      continue;
    }
    if (sessionMessageIsUserAuthored(message)) {
      continue;
    }
    final isThinking =
        message.metadata?['outputType']?.toString() == 'thinking';
    return SessionThinkingSnapshot(
      isThinking: isThinking,
      since: isThinking ? message.createdAt : null,
    );
  }
  return const SessionThinkingSnapshot(isThinking: false);
}

DateTime? sessionThinkingStartedAt({
  required Session? session,
  required Iterable<ReducerMessage> messages,
  bool? manualThinkingOverride,
}) {
  return resolveSessionThinkingSnapshot(
    session: session,
    messages: messages,
    manualThinkingOverride: manualThinkingOverride,
  ).since;
}

bool sessionTurnIsThinkingStillBlocking({
  required Session? session,
  required Iterable<ReducerMessage> messages,
  bool? manualThinkingOverride,
}) {
  return resolveSessionThinkingSnapshot(
    session: session,
    messages: messages,
    manualThinkingOverride: manualThinkingOverride,
  ).isThinking;
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

  final allMessages = messages is List<ReducerMessage>
      ? messages
      : messages.toList(growable: false);
  if (sessionTurnHasCompletionSignal(allMessages)) {
    return true;
  }
  if (sessionTurnIsThinkingStillBlocking(
    session: session,
    messages: allMessages,
  )) {
    return false;
  }
  if (sessionTurnHasBlockingToolWork(allMessages)) {
    return false;
  }
  return sessionTurnHasRenderableAgentOutput(allMessages);
}

bool sessionAbortHasSettledRemotely({
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

  if (sessionTurnHasCompletionSignal(messages)) {
    return true;
  }

  // 停止请求成功后，优先相信最新的远端会话态。
  // 这样即便历史 thinking 文本或旧工具状态还停留在消息快照里，
  // 当前会话页也能在远端实际停止后及时解除本地忙碌标记。
  return session != null && session.thinking != true;
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
  if (sessionTurnHasBlockingToolWork(latestTurnMessages)) {
    return true;
  }
  if (latestUserPrompt?.metadata?['optimistic'] == true) {
    return true;
  }
  return false;
}
