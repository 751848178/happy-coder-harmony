part of 'message_bubble.dart';

extension _MessageBubbleTooling on MessageBubble {
  Widget _buildToolCallContent(Color textColor) {
    final tool = message.tool!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOwnMessage
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.build, size: 20, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (tool.status != null) ...[
                  const SizedBox(height: 4),
                  _buildStatusBadge(tool.status!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    final statusStr = status is ToolCallStatus
        ? status.toString().split('.').last
        : 'pending';
    final viewModel = _ToolStatusBadgeViewModel.fromStatus(statusStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: viewModel.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: viewModel.color, width: 1),
      ),
      child: Text(
        viewModel.label,
        style: TextStyle(
          color: viewModel.color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPermissionRequestContent(Color textColor) {
    final permission = message.permission!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '权限请求',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            permission.tool,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnCloseContent() {
    final turnClose = message.turnClose;
    if (turnClose == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close, size: 14, color: AppTheme.neutral500),
          const SizedBox(width: 6),
          Text(
            turnClose.abandoned ? '对话已放弃' : '回合已结束',
            style: TextStyle(color: AppTheme.neutral500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    }
    return '${difference.inDays} 天前';
  }
}

class _ToolStatusBadgeViewModel {
  const _ToolStatusBadgeViewModel({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  factory _ToolStatusBadgeViewModel.fromStatus(String status) {
    switch (status) {
      case 'pending':
        return const _ToolStatusBadgeViewModel(
          color: Colors.orange,
          label: '待批准',
        );
      case 'approved':
        return const _ToolStatusBadgeViewModel(
          color: Colors.green,
          label: '已批准',
        );
      case 'rejected':
        return const _ToolStatusBadgeViewModel(
          color: Colors.red,
          label: '已拒绝',
        );
      case 'executing':
        return const _ToolStatusBadgeViewModel(
          color: Colors.blue,
          label: '执行中',
        );
      case 'completed':
        return const _ToolStatusBadgeViewModel(
          color: Colors.green,
          label: '已完成',
        );
      case 'failed':
        return const _ToolStatusBadgeViewModel(
          color: Colors.red,
          label: '失败',
        );
      default:
        return _ToolStatusBadgeViewModel(color: Colors.grey, label: status);
    }
  }
}
