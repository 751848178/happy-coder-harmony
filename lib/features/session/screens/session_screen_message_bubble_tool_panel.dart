part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolPanel on _MessageBubbleState {
  Widget _buildToolCallMessage(ToolInfo tool) {
    final status = tool.status ?? ToolCallStatus.pending;
    final isPending = status == ToolCallStatus.pending;
    final category = _toolCategory(tool.name);
    final presentation = _toolPresentationKind(tool.name);
    final primaryPath = _extractPrimaryPath(tool.arguments);
    // Use cached presentation data to avoid redundant JSON parsing.
    final cache = _toolPresentationCache;
    final command = cache?.command ?? _extractCommand(tool.arguments);
    final diffPreview = cache?.diffPreview ?? _extractDiff(tool);
    final canCollapse = cache?.canCollapse ?? _shouldCollapseToolMessage(tool);
    final argumentsPreview =
        cache?.argumentsPreview ?? (_shouldShowRawArguments(
                  tool.arguments,
                  command: command,
                  diff: diffPreview,
                ) &&
                _shouldDisplayArguments(tool.name)
            ? _formatToolArguments(tool.arguments)
            : null);
    final resultPreview =
        cache?.resultPreview ?? _formatToolResult(tool.result);
    final resultLanguage = _guessLanguageForResult(
      resultPreview,
      toolName: tool.name,
    );
    final summaryText = _toolSummaryText(tool, resultPreview: resultPreview);
    final isSubagentParent = message.hasChildren &&
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
          _buildToolCallHeader(
            tool: tool,
            status: status,
            canCollapse: canCollapse,
            category: category,
            primaryPath: primaryPath,
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
            _buildCollapsedToolPreview(
              command: command,
              diffPreview: diffPreview,
              resultPreview: resultPreview,
            ),
          ] else ...[
            ..._buildToolDetailSections(
              tool: tool,
              presentation: presentation,
              command: command,
              diffPreview: diffPreview,
              argumentsPreview: argumentsPreview,
              resultPreview: resultPreview,
              resultLanguage: resultLanguage,
              summaryText: summaryText,
            ),
            if (tool.error != null) ...[
              const SizedBox(height: 10),
              _ToolSection(
                title: '错误信息',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tool.error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            _buildPendingToolFooter(tool.id),
          ],
          if (isSubagentParent) ...[
            const SizedBox(height: 8),
            _buildSubagentChildren(),
          ],
        ],
      ),
    );
  }

  /// Renders sub-agent children inline inside a Task/Agent tool bubble.
  /// Shows child tool calls with resolved title + status icon,
  /// plus text output preview from the sub-agent.
  Widget _buildSubagentChildren() {
    final children = message.children;
    if (children.isEmpty) return const SizedBox.shrink();

    final toolChildren =
        children.where((c) => c.isToolCall && c.tool != null).toList();
    final textChildren = children.where((c) => c.isText);

    final visibleTools = toolChildren.length > 5
        ? toolChildren.sublist(0, 5)
        : toolChildren;
    final remainingCount = toolChildren.length - visibleTools.length;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutral100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in visibleTools)
            _buildSubagentChildToolRow(child),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                '…还有 $remainingCount 个工具调用',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutral500,
                ),
              ),
            ),
          if (textChildren.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _buildSubagentChildTextPreview(textChildren.last),
            ),
        ],
      ),
    );
  }

  Widget _buildSubagentChildToolRow(ReducerMessage child) {
    final tool = child.tool!;
    final toolStatus = tool.status ?? ToolCallStatus.pending;
    final icon = _toolIcon(tool.name);
    final statusIcon = _toolStatusIcon(toolStatus);
    final statusColor = _toolStatusColor(toolStatus);
    // Resolve human-readable title like upstream's extractDescription
    final resultPreview = _formatToolResult(tool.result);
    final title = _toolSummaryText(tool, resultPreview: resultPreview) ??
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

  IconData _toolStatusIcon(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending:
        return Icons.hourglass_top_rounded;
      case ToolCallStatus.approved:
        return Icons.check_circle_outline_rounded;
      case ToolCallStatus.executing:
        return Icons.sync_rounded;
      case ToolCallStatus.completed:
        return Icons.check_circle_rounded;
      case ToolCallStatus.rejected:
        return Icons.cancel_rounded;
      case ToolCallStatus.failed:
        return Icons.error_outline_rounded;
    }
  }

  Color _toolStatusColor(ToolCallStatus status) {
    switch (status) {
      case ToolCallStatus.pending:
        return AppTheme.warningColor;
      case ToolCallStatus.approved:
      case ToolCallStatus.executing:
        return AppTheme.brandColor;
      case ToolCallStatus.completed:
        return AppTheme.successColor;
      case ToolCallStatus.rejected:
        return AppTheme.neutral400;
      case ToolCallStatus.failed:
        return AppTheme.errorColor;
    }
  }

  Widget _buildSubagentChildTextPreview(ReducerMessage textChild) {
    final text = textChild.text ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final preview = text.trim();
    final truncated = preview.length > 200
        ? '${preview.substring(0, 200)}...'
        : preview;

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

  Widget _buildToolCallHeader({
    required ToolInfo tool,
    required ToolCallStatus status,
    required bool canCollapse,
    required String category,
    required String? primaryPath,
  }) =>
      _buildToolHeaderContent(
        tool: tool,
        status: status,
        canCollapse: canCollapse,
        category: category,
        primaryPath: primaryPath,
      );

  Widget _buildPendingToolFooter(String toolId) =>
      _buildPendingToolFooterContent(toolId);
}
