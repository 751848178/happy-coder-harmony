part of 'usage_statistics_screen.dart';

class _ActivityInfoSection extends StatelessWidget {
  const _ActivityInfoSection({required this.statistics});

  final UsageStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('活跃度'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: [
              _InfoRow('首次使用', _formatUsageDate(statistics.firstSessionDate)),
              const Divider(),
              _InfoRow('最近使用', _formatUsageDate(statistics.lastSessionDate)),
              const Divider(),
              _InfoRow('总会话数', '${statistics.totalSessions} 次'),
              const Divider(),
              _InfoRow('活跃天数', '${statistics.daysActive} 天'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

String _formatUsageDate(DateTime date) =>
    '${date.year}/${date.month}/${date.day}';
