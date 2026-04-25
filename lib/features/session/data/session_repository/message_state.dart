part of 'session_repository.dart';

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

  /// Optimized constructor that computes windowStartIndex once.
  factory SessionMessages.resolved({
    required List<domain.ReducerMessage> messages,
    required Map<String, domain.ReducerMessage> messagesMap,
    required domain.ReducerState reducerState,
    bool isLoaded = false,
    int? totalMessageCount,
    int? windowStartIndex,
  }) {
    final resolvedTotal = totalMessageCount ?? messages.length;
    final resolvedWindowStart = windowStartIndex ??
        _resolveLatestWindowStartIndex(
          totalMessageCount: resolvedTotal,
          loadedMessageCount: messages.length,
        );
    return SessionMessages._(
      messages: messages,
      messagesMap: messagesMap,
      reducerState: reducerState,
      isLoaded: isLoaded,
      totalMessageCount: resolvedTotal,
      windowStartIndex: resolvedWindowStart,
      hasOlderMessages: resolvedWindowStart > 0,
      hasNewerMessages: _resolveHasNewerMessages(
        messages: messages,
        totalMessageCount: resolvedTotal,
        windowStartIndex: resolvedWindowStart,
      ),
    );
  }

  SessionMessages._({
    required this.messages,
    required this.messagesMap,
    required this.reducerState,
    required this.isLoaded,
    required this.totalMessageCount,
    required this.windowStartIndex,
    required this.hasOlderMessages,
    required this.hasNewerMessages,
  });
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
