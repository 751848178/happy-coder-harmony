import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Git status
enum GitStatus {
  clean,
  modified,
  added,
  deleted,
  renamed,
  untracked,
  conflicted,
  detached,
  none,
}

/// Git branch status
enum GitBranchStatus {
  behind,
  ahead,
  diverged,
  synced,
}

/// Git repository model
class GitRepository {
  final String branch;
  final String? remoteBranch;
  final GitBranchStatus? branchStatus;
  final int commitsBehind;
  final int commitsAhead;
  final List<String> staged;
  final List<String> modified;
  final List<String> untracked;
  final String? hash;
  final String? remoteUrl;

  const GitRepository({
    required this.branch,
    this.remoteBranch,
    this.branchStatus,
    this.commitsBehind = 0,
    this.commitsAhead = 0,
    this.staged = const [],
    this.modified = const [],
    this.untracked = const [],
    this.hash,
    this.remoteUrl,
  });

  GitStatus get status {
    if (conflicted.isNotEmpty) return GitStatus.conflicted;
    if (untracked.isNotEmpty) return GitStatus.untracked;
    if (modified.isNotEmpty) return GitStatus.modified;
    if (staged.isNotEmpty) return GitStatus.added;
    return GitStatus.clean;
  }

  List<String> get conflicted => [];

  bool get hasChanges =>
      staged.isNotEmpty || modified.isNotEmpty || untracked.isNotEmpty || conflicted.isNotEmpty;

  int get totalChanges => staged.length + modified.length + untracked.length;
}

/// Git Status Badge Widget
///
/// Displays git repository status information
class GitStatusBadge extends StatelessWidget {
  const GitStatusBadge({
    super.key,
    required this.repository,
    this.showBranch = true,
    this.showChanges = true,
    this.onTap,
    this.size = GitBadgeSize.medium,
    this.showRemoteStatus = true,
  });

  final GitRepository repository;
  final bool showBranch;
  final bool showChanges;
  final VoidCallback? onTap;
  final GitBadgeSize size;
  final bool showRemoteStatus;

  double get _height {
    switch (size) {
      case GitBadgeSize.small:
        return 28;
      case GitBadgeSize.medium:
        return 32;
      case GitBadgeSize.large:
        return 40;
    }
  }

  double get _fontSize {
    switch (size) {
      case GitBadgeSize.small:
        return 11;
      case GitBadgeSize.medium:
        return 12;
      case GitBadgeSize.large:
        return 14;
    }
  }

  IconData? get _branchStatusIcon {
    if (!showRemoteStatus) return null;

    switch (repository.branchStatus) {
      case GitBranchStatus.behind:
        return Icons.arrow_downward;
      case GitBranchStatus.ahead:
        return Icons.arrow_upward;
      case GitBranchStatus.diverged:
        return Icons.compare_arrows;
      case GitBranchStatus.synced:
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = repository.status;
    final hasChanges = repository.hasChanges;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(status, hasChanges),
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(
            color: _getBorderColor(status, hasChanges),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(status),
              if (showBranch) ...[
                const SizedBox(width: 6),
                _buildBranchName(),
              ],
              if (_branchStatusIcon != null) ...[
                const SizedBox(width: 6),
                _buildBranchStatusIndicator(),
              ],
              if (showChanges && hasChanges) ...[
                const SizedBox(width: 6),
                _buildChangesIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(GitStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case GitStatus.clean:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case GitStatus.modified:
        icon = Icons.edit;
        color = AppTheme.warningColor;
        break;
      case GitStatus.added:
        icon = Icons.add_circle;
        color = AppTheme.infoColor;
        break;
      case GitStatus.deleted:
        icon = Icons.remove_circle;
        color = AppTheme.errorColor;
        break;
      case GitStatus.renamed:
        icon = Icons.drive_file_rename_outline;
        color = AppTheme.infoColor;
        break;
      case GitStatus.untracked:
        icon = Icons.help_outline;
        color = AppTheme.neutral500;
        break;
      case GitStatus.conflicted:
        icon = Icons.warning;
        color = AppTheme.errorColor;
        break;
      case GitStatus.detached:
        icon = Icons.link_off;
        color = AppTheme.warningColor;
        break;
      case GitStatus.none:
        return const SizedBox.shrink();
    }

    return Icon(icon, size: _fontSize + 4, color: color);
  }

  Widget _buildBranchName() {
    return Text(
      repository.branch,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildBranchStatusIndicator() {
    final icon = _branchStatusIcon;
    if (icon == null) return const SizedBox.shrink();

    return Icon(
      icon,
      size: _fontSize + 2,
      color: AppTheme.neutral600,
    );
  }

  Widget _buildChangesIndicator() {
    final changes = repository.totalChanges;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '+$changes',
        style: TextStyle(
          fontSize: _fontSize - 1,
          fontWeight: FontWeight.w600,
          color: AppTheme.brandColor,
        ),
      ),
    );
  }

  Color _getBackgroundColor(GitStatus status, bool hasChanges) {
    if (hasChanges) {
      return AppTheme.brandColor.withValues(alpha: 0.1);
    }
    switch (status) {
      case GitStatus.clean:
        return AppTheme.successColor.withValues(alpha: 0.1);
      case GitStatus.conflicted:
        return AppTheme.errorColor.withValues(alpha: 0.1);
      case GitStatus.detached:
        return AppTheme.warningColor.withValues(alpha: 0.1);
      default:
        return AppTheme.neutral100;
    }
  }

  Color _getBorderColor(GitStatus status, bool hasChanges) {
    if (hasChanges) {
      return AppTheme.brandColor.withValues(alpha: 0.3);
    }
    switch (status) {
      case GitStatus.clean:
        return AppTheme.successColor.withValues(alpha: 0.3);
      case GitStatus.conflicted:
        return AppTheme.errorColor.withValues(alpha: 0.3);
      case GitStatus.detached:
        return AppTheme.warningColor.withValues(alpha: 0.3);
      default:
        return AppTheme.neutral300;
    }
  }
}

/// Git status detail card
class GitStatusCard extends StatelessWidget {
  const GitStatusCard({
    super.key,
    required this.repository,
    this.onCommit,
    this.onPull,
    this.onPush,
    this.onOpenSettings,
  });

  final GitRepository repository;
  final VoidCallback? onCommit;
  final VoidCallback? onPull;
  final VoidCallback? onPush;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBranchInfo(),
            const SizedBox(height: 16),
            if (repository.hasChanges) _buildChangesSection(),
            if (!repository.hasChanges) _buildCleanState(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.account_tree,
          color: AppTheme.brandColor,
        ),
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
          Icon(
            Icons.branch,
            size: 20,
            color: AppTheme.neutral600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前分支',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral500,
                  ),
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

    Color color;
    IconData icon;
    String label;

    switch (status) {
      case GitBranchStatus.behind:
        color = AppTheme.infoColor;
        icon = Icons.arrow_downward;
        label = '落后 ${repository.commitsBehind} 提交';
        break;
      case GitBranchStatus.ahead:
        color = AppTheme.successColor;
        icon = Icons.arrow_upward;
        label = '领先 ${repository.commitsAhead} 提交';
        break;
      case GitBranchStatus.diverged:
        color = AppTheme.warningColor;
        icon = Icons.compare_arrows;
        label = '分叉';
        break;
      default:
        return const SizedBox.shrink();
    }

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

  Widget _buildChangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '文件更改',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (repository.staged.isNotEmpty)
              _ChangesChip(
                label: '已暂存',
                count: repository.staged.length,
                icon: Icons.check_circle_outline,
                color: AppTheme.successColor,
              ),
            if (repository.modified.isNotEmpty)
              _ChangesChip(
                label: '已修改',
                count: repository.modified.length,
                icon: Icons.edit_outlined,
                color: AppTheme.warningColor,
              ),
            if (repository.untracked.isNotEmpty)
              _ChangesChip(
                label: '未跟踪',
                count: repository.untracked.length,
                icon: Icons.help_outline,
                color: AppTheme.infoColor,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCleanState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 12),
          const Text(
            '工作区干净',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCommit,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('提交'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: onPull,
          icon: const Icon(Icons.download),
          tooltip: '拉取更改',
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: onPush,
          icon: const Icon(Icons.upload),
          tooltip: '推送更改',
        ),
      ],
    );
  }
}

/// Changes chip widget
class _ChangesChip extends StatelessWidget {
  const _ChangesChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label $count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Git badge size
enum GitBadgeSize {
  small,
  medium,
  large,
}
