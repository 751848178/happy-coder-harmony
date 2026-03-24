part of 'usage_statistics_screen.dart';

class _ToolsUsageSection extends StatelessWidget {
  const _ToolsUsageSection({required this.toolsUsage});

  final Map<String, int> toolsUsage;

  @override
  Widget build(BuildContext context) {
    return _UsageBreakdownSection(
      title: '工具使用',
      entries: toolsUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
      total: toolsUsage.values.fold(0, (sum, value) => sum + value),
    );
  }
}

class _ModelUsageSection extends StatelessWidget {
  const _ModelUsageSection({required this.modelUsage});

  final Map<String, int> modelUsage;

  @override
  Widget build(BuildContext context) {
    return _UsageBreakdownSection(
      title: '模型使用',
      entries: modelUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
      total: modelUsage.values.fold(0, (sum, value) => sum + value),
    );
  }
}

class _UsageBreakdownSection extends StatelessWidget {
  const _UsageBreakdownSection({
    required this.title,
    required this.entries,
    required this.total,
  });

  final String title;
  final List<MapEntry<String, int>> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: const Text(
              '暂无统计数据',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: entries
                .map((entry) => _UsageBarItem(
                      label: entry.key,
                      value: entry.value,
                      total: total,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _UsageBarItem extends StatelessWidget {
  const _UsageBarItem({
    required this.label,
    required this.value,
    required this.total,
  });

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$value 次',
                style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: AppTheme.neutral200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
