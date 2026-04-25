part of '../session_detail.dart';

extension _SessionScreenBodyFlatItemsPresenter on _SessionScreenBodyPresenter {
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
    final messageIdCounts = _messageIdCountsFor(items);
    final previousLastIndex = previousTurnGroups.length - 1;
    final previousLast = previousTurnGroups.last;
    final nextLast = nextTurnGroups[previousLastIndex];
    if (nextLast.messages.length > previousLast.messages.length) {
      items.addAll(
        _buildFlatItemsForGroup(
          nextLast,
          turnIndex: previousLastIndex,
          messageStartIndex: previousLast.messages.length,
          messageIdCounts: messageIdCounts,
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
          messageIdCounts: messageIdCounts,
        ),
      );
    }
    return List<_FlatMessageItem>.unmodifiable(items);
  }

  List<_FlatMessageItem> _buildFlatItems(List<_MessageTurnGroup> turnGroups) {
    final items = <_FlatMessageItem>[];
    final messageIdCounts = <String, int>{};
    for (var index = 0; index < turnGroups.length; index++) {
      items.addAll(
        _buildFlatItemsForGroup(
          turnGroups[index],
          turnIndex: index,
          messageIdCounts: messageIdCounts,
        ),
      );
    }
    return List<_FlatMessageItem>.unmodifiable(items);
  }

  Iterable<_FlatMessageItem> _buildFlatItemsForGroup(
    _MessageTurnGroup group, {
    required int turnIndex,
    required Map<String, int> messageIdCounts,
    int messageStartIndex = 0,
  }) sync* {
    final prompt = group.userPrompt;
    final firstReplyIndex = prompt == null ? 0 : 1;
    for (var messageIndex = messageStartIndex;
        messageIndex < group.messages.length;
        messageIndex++) {
      final message = group.messages[messageIndex];
      yield _FlatMessageItem(
        renderId: _nextMessageRenderId(message, messageIdCounts),
        message: message,
        turnGroupId: group.id,
        startsNewTurn: messageIndex == 0,
        isFirstReply: messageIndex == firstReplyIndex,
        turnIndex: turnIndex,
      );
    }
  }

  Map<String, int> _messageIdCountsFor(List<_FlatMessageItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final messageId = _messageRenderBaseId(item.message);
      counts[messageId] = (counts[messageId] ?? 0) + 1;
    }
    return counts;
  }

  String _nextMessageRenderId(
    ReducerMessage message,
    Map<String, int> messageIdCounts,
  ) {
    final baseId = _messageRenderBaseId(message);
    final occurrence = (messageIdCounts[baseId] ?? 0) + 1;
    messageIdCounts[baseId] = occurrence;
    if (occurrence == 1) {
      return baseId;
    }
    return '$baseId#$occurrence';
  }

  String _messageRenderBaseId(ReducerMessage message) {
    if (message.id.isNotEmpty) {
      return message.id;
    }
    return 'missing-message-id:${message.createdAt.microsecondsSinceEpoch}:'
        '${message.kind}';
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
    if (elapsedMilliseconds <
            _SessionScreenBodyPresenter._slowStructureBuildThresholdMs &&
        messageCount <
            _SessionScreenBodyPresenter._largeStructureMessageThreshold) {
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
