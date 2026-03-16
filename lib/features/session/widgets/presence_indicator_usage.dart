part of 'presence_indicator.dart';

class SessionUsageStats extends StatelessWidget {
  const SessionUsageStats({
    super.key,
    this.usage,
    this.presence,
  });

  final LatestUsage? usage;
  final PresenceStatus? presence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          if (presence != null) ...[
            _UsageIcon(
              icon: presence!.isOnline ? Icons.wifi : Icons.wifi_off,
              color: presence!.isOnline
                  ? AppTheme.successColor
                  : AppTheme.neutral400,
            ),
            const SizedBox(width: 16),
          ],
          if (usage != null) ...[
            _UsageIcon(
              icon: Icons.message,
              color: AppTheme.brandColor,
              label: '${usage!.messageCount}',
            ),
            const SizedBox(width: 16),
            _UsageIcon(
              icon: Icons.psychology,
              color: Colors.purple,
              label: _formatUsageNumber(usage!.tokenCount),
            ),
            const SizedBox(width: 16),
            if (usage!.filesAccessed != null)
              _UsageIcon(
                icon: Icons.folder_open,
                color: Colors.orange,
                label: '${usage!.filesAccessed}',
              ),
            const SizedBox(width: 16),
            if (usage!.toolsUsed != null)
              _UsageIcon(
                icon: Icons.build,
                color: Colors.teal,
                label: '${usage!.toolsUsed}',
              ),
          ],
        ],
      ),
    );
  }
}

class _UsageIcon extends StatelessWidget {
  const _UsageIcon({
    required this.icon,
    required this.color,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

String _formatUsageNumber(int num) {
  if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
  if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
  return num.toString();
}
