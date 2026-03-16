part of 'session_files_browser_screen.dart';

class _ChangedFileTile extends StatelessWidget {
  const _ChangedFileTile({
    required this.entry,
    required this.onTap,
  });

  final _ChangedFileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = entry.primaryChange;
    if (primary == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _sessionFileStatusColor(primary.status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _sessionFileIcon(primary.fileName),
                  color: _sessionFileStatusColor(primary.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      primary.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (entry.staged != null)
                          _StatusPill(
                            label:
                                '已暂存 · ${_sessionFileStatusLabel(entry.staged!.status)}',
                            color:
                                _sessionFileStatusColor(entry.staged!.status),
                          ),
                        if (entry.unstaged != null)
                          _StatusPill(
                            label:
                                '未暂存 · ${_sessionFileStatusLabel(entry.unstaged!.status)}',
                            color:
                                _sessionFileStatusColor(entry.unstaged!.status),
                          ),
                        if (entry.totalAdded > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.successColor,
                            valuePrefix: '+',
                          ).withValue(entry.totalAdded),
                        if (entry.totalRemoved > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.errorColor,
                            valuePrefix: '-',
                          ).withValue(entry.totalRemoved),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.code_outlined, color: AppTheme.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _sessionFileIcon(String name) {
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

Color _sessionFileStatusColor(SessionGitFileStatus status) {
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

String _sessionFileStatusLabel(SessionGitFileStatus status) {
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
