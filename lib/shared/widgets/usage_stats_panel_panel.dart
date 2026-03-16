part of 'usage_stats_panel.dart';

extension _UsageStatsPanelContent on UsageStatsPanel {
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.bar_chart, color: AppTheme.brandColor, size: 24),
        const SizedBox(width: 12),
        const Text(
          '使用统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (onPeriodChange != null) _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<UsagePeriod>(
      segments: const [
        ButtonSegment(value: UsagePeriod.today, label: Text('今天')),
        ButtonSegment(value: UsagePeriod.week, label: Text('本周')),
        ButtonSegment(value: UsagePeriod.month, label: Text('本月')),
      ],
      selected: {period},
      onSelectionChanged: (newSelection) =>
          onPeriodChange?.call(newSelection.first),
    );
  }

  Widget _buildMainMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _StatCard(
              icon: Icons.chat_bubble_outline,
              label: '消息',
              value: _formatUsageNumber(stats.totalMessages),
              color: AppTheme.brandColor,
            ),
            _StatCard(
              icon: Icons.psychology,
              label: 'Tokens',
              value: _formatUsageNumber(stats.totalTokens),
              color: AppTheme.infoColor,
            ),
            _StatCard(
              icon: Icons.history,
              label: '会话',
              value: _formatUsageNumber(stats.totalSessions),
              color: AppTheme.successColor,
            ),
            _StatCard(
              icon: Icons.timer_outlined,
              label: '使用时长',
              value: _formatUsageHours(stats.hoursSpent),
              color: AppTheme.warningColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '详细指标',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DetailedStatCard(
                icon: Icons.code,
                label: '代码生成',
                value: _formatUsageNumber(stats.codeGenerated),
                unit: '行',
                color: AppTheme.brandColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailedStatCard(
                icon: Icons.edit_document,
                label: '文件编辑',
                value: _formatUsageNumber(stats.filesEdited),
                unit: '个',
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelUsage() {
    final models = stats.modelUsage.entries.toList();
    final totalUsage = models.fold<int>(0, (sum, e) => sum + e.value);
    if (models.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型使用分布',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...models.map((entry) {
          final percentage =
              totalUsage > 0 ? (entry.value / totalUsage * 100) : 0.0;
          return _ModelUsageBar(
            modelName: entry.key,
            usage: entry.value,
            percentage: percentage,
          );
        }),
      ],
    );
  }
}

String _formatUsageNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toString();
}

String _formatUsageHours(double hours) {
  if (hours >= 1) return '${hours.toStringAsFixed(1)}h';
  return '${(hours * 60).toStringAsFixed(0)}m';
}
