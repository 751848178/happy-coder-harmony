part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolPanel on _MessageBubbleState {
  Widget _buildToolCallMessage(ToolInfo tool) {
    final status = tool.status ?? ToolCallStatus.pending;
    final isPending = status == ToolCallStatus.pending;
    final category = _toolCategory(tool.name);
    final presentation = _toolPresentationKind(tool.name);
    final command = _extractCommand(tool.arguments);
    final primaryPath = _extractPrimaryPath(tool.arguments);
    final diffPreview = _extractDiff(tool);
    final canCollapse = _shouldCollapseToolMessage(tool);
    final argumentsPreview = _shouldShowRawArguments(
              tool.arguments,
              command: command,
              diff: diffPreview,
            ) &&
            _shouldDisplayArguments(tool.name)
        ? _formatToolArguments(tool.arguments)
        : null;
    final resultPreview = _formatToolResult(tool.result);
    final resultLanguage = _guessLanguageForResult(
      resultPreview,
      toolName: tool.name,
    );
    final summaryText = _toolSummaryText(tool, resultPreview: resultPreview);

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
        ],
      ),
    );
  }
  Widget _buildToolCallHeader({
    required ToolInfo tool,
    required ToolCallStatus status,
    required bool canCollapse,
    required String category,
    required String? primaryPath,
  }) => _buildToolHeaderContent(
        tool: tool,
        status: status,
        canCollapse: canCollapse,
        category: category,
        primaryPath: primaryPath,
      );

  Widget _buildPendingToolFooter(String toolId) =>
      _buildPendingToolFooterContent(toolId);
}
