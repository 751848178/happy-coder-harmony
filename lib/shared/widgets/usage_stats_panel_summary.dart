part of 'usage_stats_panel.dart';

class UsageSummaryWidget extends StatelessWidget {
  const UsageSummaryWidget({
    super.key,
    this.onViewDetails,
    this.period = UsagePeriod.month,
  });

  final VoidCallback? onViewDetails;
  final UsagePeriod period;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandColor,
                      AppTheme.brandColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.analytics_outlined, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月使用统计',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '查看详细的使用数据和模型分布',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.neutral600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({
    super.key,
    required this.stats,
    this.onTap,
  });

  final UsageStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStatItem(
                icon: Icons.send,
                label: '消息',
                value: _formatUsageNumber(stats.totalMessages),
              ),
              _QuickStatItem(
                icon: Icons.psychology,
                label: 'Tokens',
                value: _formatUsageNumber(stats.totalTokens),
              ),
              _QuickStatItem(
                icon: Icons.timer,
                label: '时长',
                value: _formatUsageHours(stats.hoursSpent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppTheme.brandColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
        ),
      ],
    );
  }
}
