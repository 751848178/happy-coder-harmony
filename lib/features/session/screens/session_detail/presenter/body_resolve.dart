part of '../session_detail.dart';

extension _SessionScreenBodyResolvePresenter on _SessionScreenBodyPresenter {
  _SessionScreenBodyViewState resolve({
    required Session session,
    required List<ReducerMessage> messages,
    required bool hasLoadedMessages,
  }) {
    final showMessageLoading = !hasLoadedMessages && messages.isEmpty;
    final turnGroups = showMessageLoading
        ? const <_MessageTurnGroup>[]
        : resolveTurnGroups(messages);
    final sessionStats = _state._sessionOverviewCollapsed
        ? null
        : resolveSessionStats(session, messages);
    final thinkingSnapshot = resolveThinkingSnapshot(session, messages);
    final conversationBusy = _state._isConversationBusy(
      session,
      turnGroups,
      thinkingSnapshot: thinkingSnapshot,
    );
    final hasActiveResponseMarker = _state._hasEffectiveActiveResponseMarker(
      session,
      turnGroups,
      thinkingSnapshot: thinkingSnapshot,
    );
    final suppressStaleLiveState =
        _state._isRefreshingSessionState && !hasActiveResponseMarker;
    final effectiveConversationBusy =
        suppressStaleLiveState ? false : conversationBusy;
    final effectiveThinking =
        thinkingSnapshot.isThinking && !suppressStaleLiveState;
    final latestTurnMessages = turnGroups.isNotEmpty
        ? turnGroups.last.messages
        : const <ReducerMessage>[];
    return _SessionScreenBodyViewState(
      messages: messages,
      showMessageLoading: showMessageLoading,
      turnGroups: turnGroups,
      sessionStats: sessionStats,
      thinkingSnapshot: thinkingSnapshot,
      effectiveConversationBusy: effectiveConversationBusy,
      shouldKeepScreenAwake: hasActiveResponseMarker || effectiveThinking,
      latestTurnMessages: latestTurnMessages,
      showLiveReplyBadge:
          messages.isNotEmpty && effectiveThinking && !suppressStaleLiveState,
      hasStickyCandidates: _hasStickyCandidates,
    );
  }
}
