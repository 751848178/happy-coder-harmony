import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';
import '../../presentation/session_tool_visual_state.dart';
import 'collapsed_tool_preview.dart';
import 'session_message_action_types.dart';
import 'session_message_bubble_presenter.dart';
import 'subagent_children_panel.dart';
import 'tool_call_footer.dart';
import 'tool_call_header.dart';
import 'tool_call_sections.dart';
import 'tool_presentation_cache.dart';
import 'tool_shared_widgets.dart';

/// A complete tool-call message bubble — header, collapsible sections, footer, sub-agent panel.
class ToolCallBubble extends StatefulWidget {
  const ToolCallBubble({
    required this.message,
    required this.autoApproveEnabled,
    required this.isToolActionPending,
    this.onApproveTool,
    this.onRejectTool,
    this.onMessageAction,
    this.onFilePathTap,
    required this.presenter,
    required this.toolPresentationCache,
  });

  final ReducerMessage message;
  final bool autoApproveEnabled;
  final bool isToolActionPending;
  final Future<void> Function(String)? onApproveTool;
  final Future<void> Function(String, String?)? onRejectTool;
  final SessionMessageActionHandler? onMessageAction;
  final void Function(String)? onFilePathTap;
  final SessionMessageBubblePresenter presenter;
  final ToolPresentationCache? toolPresentationCache;

  @override
  State<ToolCallBubble> createState() => _ToolCallBubbleState();
}

class _ToolCallBubbleState extends State<ToolCallBubble> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.presenter
        .shouldStartCollapsed(widget.message, widget.toolPresentationCache);
  }

  @override
  void didUpdateWidget(covariant ToolCallBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message &&
        widget.presenter
            .shouldResetCollapsedState(oldWidget.message, widget.message)) {
      _collapsed = widget.presenter
          .shouldStartCollapsed(widget.message, widget.toolPresentationCache);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.message.tool!;
    final p = widget.presenter;
    final cache = widget.toolPresentationCache;

    final actualStatus = tool.status ?? ToolCallStatus.pending;
    final visualState = resolveSessionToolVisualState(
      status: actualStatus,
      autoApproveEnabled: widget.autoApproveEnabled,
      isToolActionPending: widget.isToolActionPending,
    );
    final status = visualState.status;
    // Only show pending styling in manual-approve mode.
    final isPending =
        !widget.autoApproveEnabled && status == ToolCallStatus.pending;
    final presentation = p.toolPresentationKind(tool.name);
    final command = cache?.command ?? p.extractCommand(tool.arguments);
    final diffPreview = cache?.diffPreview ?? p.extractDiff(tool);
    final canCollapse = cache?.canCollapse ?? false;
    final isSubagentParent = widget.message.hasChildren &&
        (tool.name == 'Task' || tool.name == 'Agent');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending
            ? AppTheme.warningColor.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isPending ? AppTheme.warningColor : AppTheme.neutral300,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToolCallHeader(
            tool: tool,
            status: status,
            autoApproveEnabled: widget.autoApproveEnabled,
            canCollapse: canCollapse,
            collapsed: _collapsed,
            onToggleCollapse: _toggleCollapsed,
            presenter: p,
          ),
          if (tool.description != null &&
              tool.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tool.description!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppTheme.neutral600,
              ),
            ),
          ],
          if (_collapsed && canCollapse) ...[
            const SizedBox(height: 10),
            CollapsedToolPreview(
              command: command,
              diffPreview: diffPreview,
              resultRaw: tool.result,
              presenter: p,
            ),
          ] else ...[
            ..._buildExpandedSections(
                tool, presentation, command, diffPreview, cache),
            if (tool.error != null) ...[
              const SizedBox(height: 10),
              _ErrorSection(error: tool.error!),
            ],
          ],
          if (visualState.showsManualActions ||
              visualState.showsAutoResolvingFooter) ...[
            const SizedBox(height: 10),
            ToolCallFooter(
              toolId: tool.id,
              visualState: visualState,
              actualStatus: actualStatus,
              isToolActionPending: widget.isToolActionPending,
              onApproveTool: widget.onApproveTool,
              onRejectTool: widget.onRejectTool,
            ),
          ],
          if (isSubagentParent) ...[
            const SizedBox(height: 8),
            SubagentChildrenPanel(
              children: widget.message.children,
              presenter: p,
            ),
          ],
        ],
      ),
    );
  }

  void _toggleCollapsed() => setState(() => _collapsed = !_collapsed);

  List<Widget> _buildExpandedSections(
    ToolInfo tool,
    String presentation,
    String? command,
    String? diffPreview,
    ToolPresentationCache? cache,
  ) {
    final p = widget.presenter;
    final argumentsPreview = cache?.argumentsPreview ??
        (p.shouldShowRawArguments(
                  tool.arguments,
                  command: command,
                  diff: diffPreview,
                ) &&
                p.shouldDisplayArguments(tool.name)
            ? p.formatToolArguments(tool.arguments)
            : null);
    final resultPreview =
        cache?.resultPreview ?? p.formatToolResult(tool.result);
    final resultLanguage =
        p.guessLanguageForResult(resultPreview, toolName: tool.name);
    final summaryText = p.toolSummaryText(tool, resultPreview: resultPreview);

    return ToolCallSectionBuilder(
            presenter: p, onMessageAction: widget.onMessageAction)
        .build(
      tool: tool,
      presentation: presentation,
      command: command,
      diffPreview: diffPreview,
      argumentsPreview: argumentsPreview,
      resultPreview: resultPreview,
      resultLanguage: resultLanguage,
      summaryText: summaryText,
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return ToolSection(
      title: '错误信息',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          error,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.errorColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
