part of 'session_repository.dart';

extension SessionRepositoryMessageWindows on SessionRepository {
  void prependMessageWindow(
    String sessionId,
    List<domain.ReducerMessage> olderMessages, {
    required int totalMessageCount,
    required int maxWindowSize,
  }) {
    final existing = _sessionMessages[sessionId];
    if (existing == null || olderMessages.isEmpty) {
      return;
    }

    final mergedMessages = _canonicalizeMessageWindow(<domain.ReducerMessage>[
      ...olderMessages,
      ...existing.messages,
    ]);
    var nextWindowStartIndex = existing.windowStartIndex - olderMessages.length;
    if (nextWindowStartIndex < 0) {
      nextWindowStartIndex = 0;
    }
    var nextMessages = mergedMessages;
    if (maxWindowSize > 0 && nextMessages.length > maxWindowSize) {
      nextMessages = List<domain.ReducerMessage>.unmodifiable(
        nextMessages.sublist(0, maxWindowSize),
      );
    }
    nextWindowStartIndex = _resolveWindowStartIndexFromMessages(
      nextMessages,
      fallback: nextWindowStartIndex,
    );
    final nextMessagesMap = _buildMessagesMap(nextMessages);
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: true,
      totalMessageCount: totalMessageCount,
      windowStartIndex: nextWindowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Prepended message window for session: $sessionId '
      '(prepended=${olderMessages.length}, loaded=${nextMessages.length}, '
      'total=$totalMessageCount, start=$nextWindowStartIndex)',
    );
  }

  void appendMessageWindow(
    String sessionId,
    List<domain.ReducerMessage> newerMessages, {
    required int totalMessageCount,
    required int maxWindowSize,
  }) {
    final existing = _sessionMessages[sessionId];
    if (existing == null || newerMessages.isEmpty) {
      return;
    }

    final mergedMessages = _canonicalizeMessageWindow(<domain.ReducerMessage>[
      ...existing.messages,
      ...newerMessages,
    ]);
    var nextWindowStartIndex = existing.windowStartIndex;
    var nextMessages = mergedMessages;
    if (maxWindowSize > 0 && nextMessages.length > maxWindowSize) {
      final trimFromStart = nextMessages.length - maxWindowSize;
      nextMessages = List<domain.ReducerMessage>.unmodifiable(
        nextMessages.sublist(trimFromStart),
      );
      nextWindowStartIndex += trimFromStart;
    }
    nextWindowStartIndex = _resolveWindowStartIndexFromMessages(
      nextMessages,
      fallback: nextWindowStartIndex,
    );
    final nextMessagesMap = _buildMessagesMap(nextMessages);
    _sessionMessages[sessionId] = SessionMessages(
      messages: nextMessages,
      messagesMap: nextMessagesMap,
      reducerState: existing.reducerState,
      isLoaded: true,
      totalMessageCount: totalMessageCount,
      windowStartIndex: nextWindowStartIndex,
    );
    _syncSessionPreviewFieldsFromMessages(sessionId, nextMessages.length);
    _stateController.add(
      SessionStateChange(
        type: SessionChangeType.messagesUpdated,
        sessionId: sessionId,
      ),
    );
    Logger.info(
      'Appended message window for session: $sessionId '
      '(appended=${newerMessages.length}, loaded=${nextMessages.length}, '
      'total=$totalMessageCount, start=$nextWindowStartIndex)',
    );
  }
}
