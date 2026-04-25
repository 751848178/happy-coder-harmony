part of 'git_status_badge.dart';

extension _GitStatusCardSupport on GitStatusCard {
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.account_tree, color: AppTheme.brandColor),
        const SizedBox(width: 12),
        const Text(
          'Git 状态',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: onOpenSettings,
          tooltip: 'Git 设置',
        ),
      ],
    );
  }

  Widget _buildBranchInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 20, color: AppTheme.neutral600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前分支',
                  style: TextStyle(fontSize: 11, color: AppTheme.neutral500),
                ),
                Row(
                  children: [
                    Text(
                      repository.branch,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (repository.hash != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        repository.hash!.substring(0, 7),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildBranchSyncIndicator(),
        ],
      ),
    );
  }

  Widget _buildBranchSyncIndicator() {
    final status = repository.branchStatus;
    if (status == null || status == GitBranchStatus.synced) {
      return const SizedBox.shrink();
    }
    final (color, icon, label) = switch (status) {
      GitBranchStatus.behind => (
          AppTheme.infoColor,
          Icons.arrow_downward,
          '落后 ${repository.commitsBehind} 提交',
        ),
      GitBranchStatus.ahead => (
          AppTheme.successColor,
          Icons.arrow_upward,
          '领先 ${repository.commitsAhead} 提交',
        ),
      GitBranchStatus.diverged => (
          AppTheme.warningColor,
          Icons.compare_arrows,
          '分叉',
        ),
      GitBranchStatus.synced => (AppTheme.neutral500, Icons.check, ''),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
