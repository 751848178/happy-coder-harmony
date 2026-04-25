part of '../session_detail.dart';

class _SessionMessageViewState {
  const _SessionMessageViewState({
    required this.messages,
    required this.hasLoadedMessages,
    required this.totalMessageCount,
    required this.hasOlderMessages,
    required this.hasNewerMessages,
    required this.windowStartIndex,
  });

  const _SessionMessageViewState.initial()
      : this(
          messages: const <ReducerMessage>[],
          hasLoadedMessages: false,
          totalMessageCount: 0,
          hasOlderMessages: false,
          hasNewerMessages: false,
          windowStartIndex: 0,
        );

  final List<ReducerMessage> messages;
  final bool hasLoadedMessages;
  final int totalMessageCount;
  final bool hasOlderMessages;
  final bool hasNewerMessages;
  final int windowStartIndex;

  @override
  bool operator ==(Object other) {
    return other is _SessionMessageViewState &&
        identical(messages, other.messages) &&
        hasLoadedMessages == other.hasLoadedMessages &&
        totalMessageCount == other.totalMessageCount &&
        hasOlderMessages == other.hasOlderMessages &&
        hasNewerMessages == other.hasNewerMessages &&
        windowStartIndex == other.windowStartIndex;
  }

  @override
  int get hashCode => Object.hash(
        messages,
        hasLoadedMessages,
        totalMessageCount,
        hasOlderMessages,
        hasNewerMessages,
        windowStartIndex,
      );
}
