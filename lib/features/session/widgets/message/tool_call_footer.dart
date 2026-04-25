import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';
import '../../presentation/session_tool_visual_state.dart';

/// Footer for a tool-call bubble — shows approve/reject buttons or auto-resolve indicator.
class ToolCallFooter extends StatelessWidget {
  const ToolCallFooter({
    required this.toolId,
    required this.visualState,
    required this.actualStatus,
    required this.isToolActionPending,
    this.onApproveTool,
    this.onRejectTool,
  });

  final String toolId;
  final SessionToolVisualState visualState;
  final ToolCallStatus actualStatus;
  final bool isToolActionPending;
  final Future<void> Function(String)? onApproveTool;
  final Future<void> Function(String, String?)? onRejectTool;

  @override
  Widget build(BuildContext context) {
    if (visualState.showsAutoResolvingFooter) {
      return _AutoResolvingFooter(
        isBusy: isToolActionPending ||
            actualStatus == ToolCallStatus.pending ||
            actualStatus == ToolCallStatus.approved,
      );
    }
    return _ManualActionsFooter(
      toolId: toolId,
      isToolActionPending: isToolActionPending,
      onApproveTool: onApproveTool,
      onRejectTool: onRejectTool,
    );
  }
}

class _AutoResolvingFooter extends StatelessWidget {
  const _AutoResolvingFooter({required this.isBusy});
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            if (isBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.infoColor,
                ),
              )
            else
              const Icon(Icons.sync_rounded,
                  size: 16, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '该调用正在自动处理',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.infoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualActionsFooter extends StatelessWidget {
  const _ManualActionsFooter({
    required this.toolId,
    required this.isToolActionPending,
    this.onApproveTool,
    this.onRejectTool,
  });

  final String toolId;
  final bool isToolActionPending;
  final Future<void> Function(String)? onApproveTool;
  final Future<void> Function(String, String?)? onRejectTool;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isToolActionPending)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.brandColor,
                ),
              ),
            ),
          OutlinedButton(
            onPressed: isToolActionPending
                ? null
                : () => onRejectTool?.call(toolId, null),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('拒绝'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                isToolActionPending ? null : () => onApproveTool?.call(toolId),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(isToolActionPending ? '提交中' : '批准'),
          ),
        ],
      ),
    );
  }
}
