import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';
import 'session_message_bubble_presenter.dart';

/// Collapsible panel for sub-agent children inside a Task/Agent tool bubble.
/// Defaults to collapsed with a compact summary; tap to expand.
class SubagentChildrenPanel extends StatefulWidget {
  const SubagentChildrenPanel({
    required this.children,
    required this.presenter,
  });

  final List<ReducerMessage> children;
  final SessionMessageBubblePresenter presenter;

  @override
  State<SubagentChildrenPanel> createState() => _SubagentChildrenPanelState();
}

class _SubagentChildrenPanelState extends State<SubagentChildrenPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    final toolChildren =
        children.where((c) => c.isToolCall && c.tool != null).toList();
    final textChildren = children.where((c) => c.isText).toList();

    if (toolChildren.isEmpty && textChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    final failedCount = toolChildren
        .where((c) =>
            c.tool?.status == ToolCallStatus.failed ||
            c.tool?.status == ToolCallStatus.rejected)
        .length;
    final isRunning = toolChildren.any((c) =>
        c.tool?.status == ToolCallStatus.pending ||
        c.tool?.status == ToolCallStatus.executing ||
        c.tool?.status == ToolCallStatus.approved);

    final statusLabel = isRunning
        ? '进行中'
        : failedCount > 0
            ? '$failedCount 失败'
            : '已完成';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.neutral100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      toolChildren.isNotEmpty
                          ? '${toolChildren.length} 个工具调用 · $statusLabel'
                          : '子任务输出',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppTheme.neutral500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final child in toolChildren.take(5))
                    _SubagentToolRow(
                      child: child,
                      presenter: widget.presenter,
                    ),
                  if (toolChildren.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                        '…还有 ${toolChildren.length - 5} 个工具调用',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ),
                  if (textChildren.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: _SubagentTextPreview(child: textChildren.last),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubagentToolRow extends StatelessWidget {
  const _SubagentToolRow({required this.child, required this.presenter});
  final ReducerMessage child;
  final SessionMessageBubblePresenter presenter;

  @override
  Widget build(BuildContext context) {
    final tool = child.tool!;
    final toolStatus = tool.status ?? ToolCallStatus.pending;
    final icon = presenter.toolIcon(tool.name);
    final statusIcon = _toolStatusIcon(toolStatus);
    final statusColor = _toolStatusColor(toolStatus);
    final title = presenter.toolSummaryText(
          tool,
          resultPreview: presenter.plainTextPreview(tool.result ?? ''),
        ) ??
        tool.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.neutral500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(statusIcon, size: 13, color: statusColor),
        ],
      ),
    );
  }

  static IconData _toolStatusIcon(ToolCallStatus status) => switch (status) {
        ToolCallStatus.pending => Icons.hourglass_top_rounded,
        ToolCallStatus.approved => Icons.check_circle_outline_rounded,
        ToolCallStatus.executing => Icons.sync_rounded,
        ToolCallStatus.completed => Icons.check_circle_rounded,
        ToolCallStatus.rejected => Icons.cancel_rounded,
        ToolCallStatus.failed => Icons.error_outline_rounded,
      };

  static Color _toolStatusColor(ToolCallStatus status) => switch (status) {
        ToolCallStatus.pending => AppTheme.warningColor,
        ToolCallStatus.approved => AppTheme.brandColor,
        ToolCallStatus.executing => AppTheme.brandColor,
        ToolCallStatus.completed => AppTheme.successColor,
        ToolCallStatus.rejected => AppTheme.neutral400,
        ToolCallStatus.failed => AppTheme.errorColor,
      };
}

class _SubagentTextPreview extends StatelessWidget {
  const _SubagentTextPreview({required this.child});
  final ReducerMessage child;

  @override
  Widget build(BuildContext context) {
    final text = child.text ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final preview = text.trim();
    final truncated =
        preview.length > 200 ? '${preview.substring(0, 200)}...' : preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        truncated,
        style: const TextStyle(
          fontSize: 11,
          height: 1.4,
          color: AppTheme.neutral600,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
