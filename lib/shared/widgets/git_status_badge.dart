import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'git_status_badge_card.dart';
part 'git_status_badge_card_actions.dart';
part 'git_status_badge_card_support.dart';
part 'git_status_badge_widget.dart';

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

/// Git badge size
enum GitBadgeSize {
  small,
  medium,
  large,
}

/// Git repository model
class GitRepository {
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

  List<String> get conflicted => [];

  GitStatus get status {
    if (conflicted.isNotEmpty) return GitStatus.conflicted;
    if (untracked.isNotEmpty) return GitStatus.untracked;
    if (modified.isNotEmpty) return GitStatus.modified;
    if (staged.isNotEmpty) return GitStatus.added;
    return GitStatus.clean;
  }

  bool get hasChanges =>
      staged.isNotEmpty ||
      modified.isNotEmpty ||
      untracked.isNotEmpty ||
      conflicted.isNotEmpty;

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

  @override
  Widget build(BuildContext context) {
    final status = repository.status;
    final hasChanges = repository.hasChanges;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _badgeHeight,
        decoration: BoxDecoration(
          color: _badgeBackgroundColor(status, hasChanges),
          borderRadius: BorderRadius.circular(_badgeHeight / 2),
          border: Border.all(
            color: _badgeBorderColor(status, hasChanges),
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
}
