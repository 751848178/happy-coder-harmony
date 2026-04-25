import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'message_action_context_menu.dart';
import 'session_message_action_types.dart';

/// A titled section container used inside tool-call bubbles.
class ToolSection extends StatelessWidget {
  const ToolSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A rounded card that displays a short text summary with context-menu support.
class ToolSummaryCard extends StatelessWidget {
  const ToolSummaryCard({required this.text, this.onMessageAction});
  final String text;
  final SessionMessageActionHandler? onMessageAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: SelectableText(
        text,
        contextMenuBuilder: buildMessageActionContextMenu(onMessageAction),
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppTheme.neutral800,
        ),
      ),
    );
  }
}

/// Renders a list of todo items with status indicators.
class ToolTodoList extends StatelessWidget {
  const ToolTodoList({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ToolTodoRow(item: items[i]),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// A single todo row with status-colored icon.
class ToolTodoRow extends StatelessWidget {
  const ToolTodoRow({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final map = item is Map ? item : const <String, dynamic>{};
    final content = map['content']?.toString() ?? item.toString();
    final status = map['status']?.toString() ?? 'pending';
    final color = switch (status) {
      'completed' => AppTheme.successColor,
      'in_progress' => AppTheme.infoColor,
      _ => AppTheme.neutral500,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            status == 'completed'
                ? Icons.check_circle_rounded
                : status == 'in_progress'
                    ? Icons.timelapse_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.neutral800,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small pill chip used for turn metadata labels.
class TurnMetaChip extends StatelessWidget {
  const TurnMetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}
