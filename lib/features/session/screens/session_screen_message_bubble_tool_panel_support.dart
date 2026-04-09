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

  Widget _buildToolFooterContent(
    String toolId, {
    required SessionToolVisualState visualState,
    required ToolCallStatus actualStatus,
  }) {
    if (visualState.showsAutoResolvingFooter) {
      final isBusy = isToolActionPending ||
          actualStatus == ToolCallStatus.pending ||
          actualStatus == ToolCallStatus.approved;
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
                const Icon(
                  Icons.sync_rounded,
                  size: 16,
                  color: AppTheme.infoColor,
                ),
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
      ),
    );
  }
}
