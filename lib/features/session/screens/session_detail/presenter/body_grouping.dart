part of '../session_detail.dart';

extension _SessionScreenBodyGroupingPresenter on _SessionScreenBodyPresenter {
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
      for (var index = 0; index < items.length; index++)
        items[index].renderId: index,
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
}
