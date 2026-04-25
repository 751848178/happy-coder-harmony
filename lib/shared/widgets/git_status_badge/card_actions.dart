part of 'git_status_badge.dart';

extension _GitStatusCardActions on GitStatusCard {
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
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.successColor),
          SizedBox(width: 12),
          Text(
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
