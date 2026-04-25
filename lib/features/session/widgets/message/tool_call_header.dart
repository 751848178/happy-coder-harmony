import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';
import 'session_message_bubble_presenter.dart';
import 'tool_shared_widgets.dart';

/// Header row for a tool-call bubble: icon, title, status badge, collapse toggle, meta chips.
class ToolCallHeader extends StatelessWidget {
  const ToolCallHeader({
    required this.tool,
    required this.status,
    required this.canCollapse,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.presenter,
    this.autoApproveEnabled = false,
  });

  final ToolInfo tool;
  final ToolCallStatus status;
  final bool canCollapse;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final SessionMessageBubblePresenter presenter;
  final bool autoApproveEnabled;

  @override
  Widget build(BuildContext context) {
    final category = presenter.toolCategory(tool.name);
    final primaryPath = presenter.extractPrimaryPath(tool.arguments);
    // In auto-approve mode, hide badge once past pending (approved/executing).
    final showBadge = !autoApproveEnabled ||
        status == ToolCallStatus.pending ||
        status == ToolCallStatus.completed ||
        status == ToolCallStatus.failed ||
        status == ToolCallStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              presenter.toolIcon(tool.name),
              color: status == ToolCallStatus.pending
                  ? AppTheme.warningColor
                  : AppTheme.neutral600,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                presenter.toolTitle(tool.name),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showBadge) _ToolStatusBadge(status: status),
            if (canCollapse) ...[
              const SizedBox(width: 8),
              _CollapseButton(
                collapsed: collapsed,
                onToggle: onToggleCollapse,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TurnMetaChip(label: category),
            if (primaryPath != null && primaryPath.isNotEmpty)
              TurnMetaChip(label: primaryPath),
          ],
        ),
      ],
    );
  }
}

class _ToolStatusBadge extends StatelessWidget {
  const _ToolStatusBadge({required this.status});
  final ToolCallStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      ToolCallStatus.pending => (AppTheme.warningColor, '待确认'),
      ToolCallStatus.approved => (AppTheme.infoColor, '已处理'),
      ToolCallStatus.rejected => (AppTheme.errorColor, '已拒绝'),
      ToolCallStatus.executing => (AppTheme.infoColor, '执行中'),
      ToolCallStatus.completed => (AppTheme.infoColor, '已完成'),
      ToolCallStatus.failed => (AppTheme.errorColor, '失败'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.collapsed, required this.onToggle});
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          collapsed ? '展开' : '收起',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.brandColor,
          ),
        ),
      ),
    );
  }
}
