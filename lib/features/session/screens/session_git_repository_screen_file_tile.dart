part of 'session_git_repository_screen.dart';

class _ProjectTreeFileTile extends StatelessWidget {
  const _ProjectTreeFileTile({
    required this.entry,
    required this.depth,
    required this.onTap,
  });

  final _ProjectFileEntry entry;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final staged = entry.staged;
    final unstaged = entry.unstaged;
    final isChanged = entry.isChanged;
    final totalAdded = (staged?.addedLines ?? 0) + (unstaged?.addedLines ?? 0);
    final totalRemoved =
        (staged?.removedLines ?? 0) + (unstaged?.removedLines ?? 0);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: EdgeInsets.fromLTRB(22 + (depth * 18), 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isChanged
                  ? AppTheme.brandColor.withValues(alpha: 0.2)
                  : AppTheme.neutral200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileIcon(isChanged),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildFileInfo(
                      staged, unstaged, totalAdded, totalRemoved, isChanged)),
              const SizedBox(width: 8),
              Icon(
                isChanged ? Icons.code_outlined : Icons.chevron_right,
                color: AppTheme.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(bool isChanged) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: (isChanged ? AppTheme.brandColor : AppTheme.neutral400)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _ProjectFilePresentation.iconForFile(entry.file.fileName),
        color: isChanged ? AppTheme.brandColor : AppTheme.neutral700,
      ),
    );
  }

  Widget _buildFileInfo(
    SessionGitFile? staged,
    SessionGitFile? unstaged,
    int totalAdded,
    int totalRemoved,
    bool isChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.file.fileName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (depth == 0) ...[
          const SizedBox(height: 4),
          Text(
            entry.file.filePath,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.neutral600, height: 1.4),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (staged != null)
              _StatusPill(
                label:
                    '已暂存 · ${_ProjectFilePresentation.statusLabel(staged.status)}',
                color: _ProjectFilePresentation.statusColor(staged.status),
              ),
            if (unstaged != null)
              _StatusPill(
                label:
                    '未暂存 · ${_ProjectFilePresentation.statusLabel(unstaged.status)}',
                color: _ProjectFilePresentation.statusColor(unstaged.status),
              ),
            if (totalAdded > 0)
              const _StatusPill(
                      label: '', color: AppTheme.successColor, valuePrefix: '+')
                  .withValue(totalAdded),
            if (totalRemoved > 0)
              const _StatusPill(
                      label: '', color: AppTheme.errorColor, valuePrefix: '-')
                  .withValue(totalRemoved),
            if (!isChanged)
              const _StatusPill(label: '未改动', color: AppTheme.neutral600),
          ],
        ),
      ],
    );
  }
}

class _ProjectFilePresentation {
  const _ProjectFilePresentation._();

  static IconData iconForFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.dart') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.tsx') ||
        lower.endsWith('.jsx') ||
        lower.endsWith('.py') ||
        lower.endsWith('.go') ||
        lower.endsWith('.java') ||
        lower.endsWith('.kt') ||
        lower.endsWith('.swift') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml')) {
      return Icons.code_outlined;
    }
    if (lower.endsWith('.md')) {
      return Icons.notes_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static String statusLabel(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return '新增';
      case SessionGitFileStatus.deleted:
        return '删除';
      case SessionGitFileStatus.renamed:
        return '重命名';
      case SessionGitFileStatus.untracked:
        return '未跟踪';
      case SessionGitFileStatus.modified:
        return '修改';
    }
  }

  static Color statusColor(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return AppTheme.successColor;
      case SessionGitFileStatus.deleted:
        return AppTheme.errorColor;
      case SessionGitFileStatus.renamed:
        return AppTheme.infoColor;
      case SessionGitFileStatus.untracked:
        return AppTheme.neutral600;
      case SessionGitFileStatus.modified:
        return AppTheme.warningColor;
    }
  }
}
