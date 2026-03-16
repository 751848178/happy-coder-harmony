part of 'session_git_repository_screen.dart';

class _RepositoryFolderTile extends StatelessWidget {
  const _RepositoryFolderTile({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.onTap,
  });

  final _RepositoryTreeNode node;
  final int depth;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: EdgeInsets.fromLTRB(14 + (depth * 18), 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_outlined,
                    color: AppTheme.warningColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildFolderText()),
              if (node.changedCount > 0) _buildChangedBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          node.changedCount > 0
              ? '${node.fileCount} 个文件 · ${node.changedCount} 个有改动'
              : '${node.fileCount} 个文件',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.neutral600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildChangedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${node.changedCount}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.brandColor,
        ),
      ),
    );
  }
}
