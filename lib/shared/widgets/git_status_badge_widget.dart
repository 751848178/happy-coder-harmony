part of 'git_status_badge.dart';

extension _GitStatusBadgeWidget on GitStatusBadge {
  double get _badgeHeight => switch (size) {
        GitBadgeSize.small => 28,
        GitBadgeSize.medium => 32,
        GitBadgeSize.large => 40,
      };

  double get _badgeFontSize => switch (size) {
        GitBadgeSize.small => 11,
        GitBadgeSize.medium => 12,
        GitBadgeSize.large => 14,
      };

  IconData? get _branchStatusIcon {
    if (!showRemoteStatus) return null;
    return switch (repository.branchStatus) {
      GitBranchStatus.behind => Icons.arrow_downward,
      GitBranchStatus.ahead => Icons.arrow_upward,
      GitBranchStatus.diverged => Icons.compare_arrows,
      GitBranchStatus.synced || null => null,
    };
  }

  Widget _buildStatusIcon(GitStatus status) {
    if (status == GitStatus.none) return const SizedBox.shrink();
    final (icon, color) = switch (status) {
      GitStatus.clean => (Icons.check_circle, AppTheme.successColor),
      GitStatus.modified => (Icons.edit, AppTheme.warningColor),
      GitStatus.added => (Icons.add_circle, AppTheme.infoColor),
      GitStatus.deleted => (Icons.remove_circle, AppTheme.errorColor),
      GitStatus.renamed => (
          Icons.drive_file_rename_outline,
          AppTheme.infoColor
        ),
      GitStatus.untracked => (Icons.help_outline, AppTheme.neutral500),
      GitStatus.conflicted => (Icons.warning, AppTheme.errorColor),
      GitStatus.detached => (Icons.link_off, AppTheme.warningColor),
      GitStatus.none => (Icons.circle, AppTheme.neutral400),
    };
    return Icon(icon, size: _badgeFontSize + 4, color: color);
  }

  Widget _buildBranchName() {
    return Text(
      repository.branch,
      style: TextStyle(
        fontSize: _badgeFontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildBranchStatusIndicator() {
    final icon = _branchStatusIcon;
    if (icon == null) return const SizedBox.shrink();
    return Icon(icon, size: _badgeFontSize + 2, color: AppTheme.neutral600);
  }

  Widget _buildChangesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '+${repository.totalChanges}',
        style: TextStyle(
          fontSize: _badgeFontSize - 1,
          fontWeight: FontWeight.w600,
          color: AppTheme.brandColor,
        ),
      ),
    );
  }

  Color _badgeBackgroundColor(GitStatus status, bool hasChanges) {
    if (hasChanges) return AppTheme.brandColor.withValues(alpha: 0.1);
    return switch (status) {
      GitStatus.clean => AppTheme.successColor.withValues(alpha: 0.1),
      GitStatus.conflicted => AppTheme.errorColor.withValues(alpha: 0.1),
      GitStatus.detached => AppTheme.warningColor.withValues(alpha: 0.1),
      _ => AppTheme.neutral100,
    };
  }

  Color _badgeBorderColor(GitStatus status, bool hasChanges) {
    if (hasChanges) return AppTheme.brandColor.withValues(alpha: 0.3);
    return switch (status) {
      GitStatus.clean => AppTheme.successColor.withValues(alpha: 0.3),
      GitStatus.conflicted => AppTheme.errorColor.withValues(alpha: 0.3),
      GitStatus.detached => AppTheme.warningColor.withValues(alpha: 0.3),
      _ => AppTheme.neutral300,
    };
  }
}
