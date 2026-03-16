part of 'usage_statistics_screen.dart';

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.statistics});

  final UsageStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.message_outlined,
        label: '消息总数',
        value: statistics.totalMessages.toString(),
        color: AppTheme.brandColor,
      ),
      _StatCard(
        icon: Icons.psychology_outlined,
        label: 'Token 总量',
        value: _formatUsageNumber(statistics.totalTokens),
        color: Colors.purple,
      ),
      _StatCard(
        icon: Icons.attach_money,
        label: '累计花费',
        value: '\$${statistics.totalCost.toStringAsFixed(2)}',
        color: Colors.green,
      ),
      _StatCard(
        icon: Icons.folder_open_outlined,
        label: '访问文件数',
        value: statistics.totalFilesAccessed.toString(),
        color: Colors.orange,
      ),
      _StatCard(
        icon: Icons.calendar_today_outlined,
        label: '活跃天数',
        value: '${statistics.daysActive} 天',
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.build_circle_outlined,
        label: '工具调用数',
        value: statistics.totalToolsUsed.toString(),
        color: Colors.teal,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('概览'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 142,
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatUsageNumber(int num) {
  if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
  if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
  return num.toString();
}
