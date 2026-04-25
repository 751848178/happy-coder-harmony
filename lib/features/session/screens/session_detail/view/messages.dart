part of '../session_detail.dart';

/// A flat list item representing a single message with turn-group metadata.
/// Used by [_buildMessageList] to virtualize at the per-message level instead
/// of per-turn-group level, avoiding the O(turn_size) Column layout for all
/// messages in a turn when only some are visible.
class _FlatMessageItem {
  const _FlatMessageItem({
    required this.renderId,
    required this.message,
    required this.turnGroupId,
    required this.startsNewTurn,
    required this.isFirstReply,
    required this.turnIndex,
  });

  final String renderId;
  final ReducerMessage message;
  final String turnGroupId;
  final bool startsNewTurn;
  final bool isFirstReply;
  final int turnIndex;
}
