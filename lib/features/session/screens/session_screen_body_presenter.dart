part of 'session_screen.dart';

class _SessionScreenBodyViewState {
  const _SessionScreenBodyViewState({
    required this.messages,
    required this.showMessageLoading,
    required this.turnGroups,
    required this.sessionStats,
    required this.thinkingSnapshot,
    required this.effectiveConversationBusy,
    required this.shouldKeepScreenAwake,
    required this.latestTurnMessages,
    required this.showLiveReplyBadge,
    required this.hasStickyCandidates,
  });

  final List<ReducerMessage> messages;
  final bool showMessageLoading;
  final List<_MessageTurnGroup> turnGroups;
  final SessionStats? sessionStats;
  final SessionThinkingSnapshot thinkingSnapshot;
  final bool effectiveConversationBusy;
  final bool shouldKeepScreenAwake;
  final List<ReducerMessage> latestTurnMessages;
  final bool showLiveReplyBadge;
  final bool hasStickyCandidates;
}

class _SessionScreenBodyPresenter {
  static const int _slowStructureBuildThresholdMs = 8;
  static const int _largeStructureMessageThreshold = 120;

  _SessionScreenBodyPresenter(this._state);

  final _SessionScreenState _state;

  Session? _cachedStatsSession;
  List<ReducerMessage>? _cachedStatsMessages;
  SessionStats? _cachedSessionStats;
  Session? _cachedThinkingSession;
  List<ReducerMessage>? _cachedThinkingMessages;
  SessionThinkingSnapshot _cachedThinkingSnapshot =
      const SessionThinkingSnapshot(isThinking: false);
  List<ReducerMessage>? _cachedTurnGroupMessages;
  List<_MessageTurnGroup> _cachedTurnGroups = const <_MessageTurnGroup>[];
  List<_MessageTurnGroup>? _cachedFlatItemTurnGroups;
  List<_FlatMessageItem> _cachedFlatItems = const <_FlatMessageItem>[];
  Map<String, int> _cachedFlatItemIndexes = const <String, int>{};
  List<_MessageTurnGroup>? _cachedTurnGroupIndexSource;
  Map<String, int> _cachedTurnGroupIndexes = const <String, int>{};
  bool _hasStickyCandidates = false;

  bool get hasStickyCandidates => _hasStickyCandidates;

  int? findFlatItemIndexByMessageId(String messageId) {
    return _cachedFlatItemIndexes[messageId];
  }

  int? findTurnGroupIndexById(String turnGroupId) {
    return _cachedTurnGroupIndexes[turnGroupId];
  }

  SessionStats? resolveSessionStats(
    Session? session,
    List<ReducerMessage> messages,
  ) {
    if (session == null) {
      return null;
    }
    if (identical(_cachedStatsSession, session) &&
        identical(_cachedStatsMessages, messages)) {
      return _cachedSessionStats;
    }
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: messages,
    );
    _cachedStatsSession = session;
    _cachedStatsMessages = messages;
    _cachedSessionStats = stats;
    return stats;
  }

  SessionThinkingSnapshot resolveThinkingSnapshot(
    Session session,
    List<ReducerMessage> messages,
  ) {
    if (!identical(_cachedThinkingSession, session) ||
        !identical(_cachedThinkingMessages, messages)) {
      _cachedThinkingSession = session;
      _cachedThinkingMessages = messages;
      _cachedThinkingSnapshot = resolveSessionThinkingSnapshot(
        session: session,
        messages: messages,
      );
    }
    return _cachedThinkingSnapshot;
  }

  List<_MessageTurnGroup> resolveTurnGroups(List<ReducerMessage> messages) {
    if (identical(_cachedTurnGroupMessages, messages)) {
      return _cachedTurnGroups;
    }
    final previousMessages = _cachedTurnGroupMessages;
    final canAppend = _canAppendTurnGroups(
      previousMessages: previousMessages,
      nextMessages: messages,
    );
    final stopwatch = Stopwatch()..start();
    final groups = canAppend
        ? _appendTurnGroups(
            previousMessages: previousMessages!,
            nextMessages: messages,
          )
        : _MessageTurnGroup.build(messages);
    stopwatch.stop();
    _cachedTurnGroupMessages = messages;
    _cachedTurnGroups = groups;
    _hasStickyCandidates = _state._initialLoadComplete &&
        !_state._collapseAllTurns &&
        groups.any(
          (group) => group.userPrompt != null && group.messages.length > 1,
        );
    _logStructureBuild(
      stage: 'turn-groups',
      elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      messageCount: messages.length,
      groupCount: groups.length,
      appendMode: canAppend,
    );
    return groups;
  }

  List<_FlatMessageItem> resolveFlatItems(List<_MessageTurnGroup> turnGroups) {
    if (identical(_cachedFlatItemTurnGroups, turnGroups)) {
      return _cachedFlatItems;
    }
    final previousTurnGroups = _cachedFlatItemTurnGroups;
    final canAppend = _canAppendFlatItems(
      previousTurnGroups: previousTurnGroups,
      nextTurnGroups: turnGroups,
    );
    final stopwatch = Stopwatch()..start();
    final items = canAppend
        ? _appendFlatItems(
            previousTurnGroups: previousTurnGroups!,
            nextTurnGroups: turnGroups,
          )
        : _buildFlatItems(turnGroups);
    stopwatch.stop();
    _cachedFlatItemTurnGroups = turnGroups;
    _cachedFlatItems = items;
    _cachedFlatItemIndexes = <String, int>{
      for (var index = 0; index < items.length; index++) items[index].message.id: index,
    };
    _logStructureBuild(
      stage: 'flat-items',
      elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      messageCount: items.length,
      groupCount: turnGroups.length,
      itemCount: items.length,
      appendMode: canAppend,
    );
    return items;
  }

  Map<String, int> resolveTurnGroupIndexes(List<_MessageTurnGroup> turnGroups) {
    if (identical(_cachedTurnGroupIndexSource, turnGroups)) {
      return _cachedTurnGroupIndexes;
    }
    _cachedTurnGroupIndexSource = turnGroups;
    return _cachedTurnGroupIndexes = <String, int>{
      for (var index = 0; index < turnGroups.length; index++)
        turnGroups[index].id: index,
    };
  }

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

  bool _canAppendTurnGroups({
    required List<ReducerMessage>? previousMessages,
    required List<ReducerMessage> nextMessages,
  }) {
    if (previousMessages == null ||
        previousMessages.isEmpty ||
        nextMessages.length <= previousMessages.length) {
      return false;
    }
    for (var index = 0; index < previousMessages.length; index++) {
      if (!identical(previousMessages[index], nextMessages[index])) {
        return false;
      }
    }
    return true;
  }

  List<_MessageTurnGroup> _appendTurnGroups({
    required List<ReducerMessage> previousMessages,
    required List<ReducerMessage> nextMessages,
  }) {
    final groups = List<_MessageTurnGroup>.from(_cachedTurnGroups);
    for (var index = previousMessages.length;
        index < nextMessages.length;
        index++) {
      final message = nextMessages[index];
      if (groups.isEmpty || _MessageTurnGroup.startsNewTurn(message)) {
        groups.add(_MessageTurnGroup.single(message));
        continue;
      }
      final lastGroup = groups.removeLast();
      groups.add(lastGroup.append(message));
    }
    return List<_MessageTurnGroup>.unmodifiable(groups);
  }

  bool _canAppendFlatItems({
    required List<_MessageTurnGroup>? previousTurnGroups,
    required List<_MessageTurnGroup> nextTurnGroups,
  }) {
    if (previousTurnGroups == null ||
        previousTurnGroups.isEmpty ||
        nextTurnGroups.length < previousTurnGroups.length) {
      return false;
    }
    final fixedPrefixLength = previousTurnGroups.length - 1;
    for (var index = 0; index < fixedPrefixLength; index++) {
      if (!identical(previousTurnGroups[index], nextTurnGroups[index])) {
        return false;
      }
    }
    final previousLast = previousTurnGroups.last;
    final nextLast = nextTurnGroups[previousTurnGroups.length - 1];
    if (previousLast.id != nextLast.id) {
      return false;
    }
    final previousMessages = previousLast.messages;
    final nextMessages = nextLast.messages;
    if (nextMessages.length < previousMessages.length) {
      return false;
    }
    for (var index = 0; index < previousMessages.length; index++) {
      if (!identical(previousMessages[index], nextMessages[index])) {
        return false;
      }
    }
    return true;
  }

  List<_FlatMessageItem> _appendFlatItems({
    required List<_MessageTurnGroup> previousTurnGroups,
    required List<_MessageTurnGroup> nextTurnGroups,
  }) {
    final items = List<_FlatMessageItem>.from(_cachedFlatItems);
    final previousLastIndex = previousTurnGroups.length - 1;
    final previousLast = previousTurnGroups.last;
    final nextLast = nextTurnGroups[previousLastIndex];
    if (nextLast.messages.length > previousLast.messages.length) {
      items.addAll(
        _buildFlatItemsForGroup(
          nextLast,
          turnIndex: previousLastIndex,
          messageStartIndex: previousLast.messages.length,
        ),
      );
    }
    for (var index = previousTurnGroups.length;
        index < nextTurnGroups.length;
        index++) {
      items.addAll(
        _buildFlatItemsForGroup(
          nextTurnGroups[index],
          turnIndex: index,
        ),
      );
    }
    return List<_FlatMessageItem>.unmodifiable(items);
  }

  List<_FlatMessageItem> _buildFlatItems(List<_MessageTurnGroup> turnGroups) {
    final items = <_FlatMessageItem>[];
    for (var index = 0; index < turnGroups.length; index++) {
      items.addAll(
        _buildFlatItemsForGroup(
          turnGroups[index],
          turnIndex: index,
        ),
      );
    }
    return List<_FlatMessageItem>.unmodifiable(items);
  }

  Iterable<_FlatMessageItem> _buildFlatItemsForGroup(
    _MessageTurnGroup group, {
    required int turnIndex,
    int messageStartIndex = 0,
  }) sync* {
    final prompt = group.userPrompt;
    final firstReplyIndex = prompt == null ? 0 : 1;
    for (var messageIndex = messageStartIndex;
        messageIndex < group.messages.length;
        messageIndex++) {
      final message = group.messages[messageIndex];
      yield _FlatMessageItem(
        message: message,
        turnGroupId: group.id,
        startsNewTurn: messageIndex == 0,
        isFirstReply: messageIndex == firstReplyIndex,
        turnIndex: turnIndex,
      );
    }
  }

  void _logStructureBuild({
    required String stage,
    required int elapsedMilliseconds,
    required int messageCount,
    required int groupCount,
    int? itemCount,
    required bool appendMode,
  }) {
    if (!_sessionVerbosePerfLogging) {
      return;
    }
    if (elapsedMilliseconds < _slowStructureBuildThresholdMs &&
        messageCount < _largeStructureMessageThreshold) {
      return;
    }
    Logger.info(
      '[SessionPerf][$stage] session=${_state.widget.sessionId} '
      'messages=$messageCount groups=$groupCount '
      '${itemCount == null ? '' : 'items=$itemCount '}'
      'mode=${appendMode ? "append" : "full"} '
      'cost=${elapsedMilliseconds}ms',
    );
  }
}
