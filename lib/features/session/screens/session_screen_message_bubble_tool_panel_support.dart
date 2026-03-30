part of 'session_screen.dart';

extension _SessionScreenMessageBubbleToolPanelSupport on _MessageBubbleState {
  Widget _buildToolHeaderContent({
    required ToolInfo tool,
    required ToolCallStatus status,
    required bool canCollapse,
    required String category,
    required String? primaryPath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _toolIcon(tool.name),
              color: status == ToolCallStatus.pending
                  ? AppTheme.warningColor
                  : AppTheme.neutral600,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                _toolTitle(tool.name),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildToolStatusBadge(status),
            if (canCollapse) ...[
              const SizedBox(width: 8),
              _buildCollapseButton(
                color: AppTheme.brandColor,
                collapsedLabel: '展开',
                expandedLabel: '收起',
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TurnMetaChip(label: category),
            if (primaryPath != null && primaryPath.isNotEmpty)
              _TurnMetaChip(label: primaryPath),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingToolFooterContent(String toolId) {
    if (autoApproveEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            if (isToolActionPending)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.successColor,
                ),
              )
            else
              const Icon(
                Icons.auto_mode_rounded,
                size: 16,
                color: AppTheme.successColor,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isToolActionPending ? '正在自动批准这次调用…' : '当前权限模式会自动处理这次调用',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
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
          onPressed:
              isToolActionPending ? null : () => onRejectTool(toolId, null),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            foregroundColor: AppTheme.errorColor,
            side: const BorderSide(color: AppTheme.errorColor),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('拒绝'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isToolActionPending ? null : () => onApproveTool(toolId),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: AppTheme.successColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(isToolActionPending ? '提交中' : '批准'),
        ),
      ],
    );
  }
}
