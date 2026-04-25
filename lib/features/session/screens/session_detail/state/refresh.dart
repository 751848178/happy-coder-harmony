part of '../session_detail.dart';

class _MessageViewportAnchor {
  const _MessageViewportAnchor({
    required this.messageId,
    required this.rowId,
    required this.distanceFromViewportEdge,
    required this.alignToBottom,
    this.messageIndex,
  });

  final String messageId;
  final String rowId;
  final double distanceFromViewportEdge;
  final bool alignToBottom;
  final int? messageIndex;
}
