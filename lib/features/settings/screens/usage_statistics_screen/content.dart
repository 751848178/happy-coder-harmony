part of 'usage_statistics_screen.dart';

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.statistics});

  final UsageStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummarySection(statistics: statistics),
          const SizedBox(height: 24),
          _DailyUsageSection(dailyUsage: statistics.dailyUsage),
          const SizedBox(height: 24),
          _ToolsUsageSection(toolsUsage: statistics.toolsUsage),
          const SizedBox(height: 24),
          _ModelUsageSection(modelUsage: statistics.modelUsage),
          const SizedBox(height: 24),
          _ActivityInfoSection(statistics: statistics),
        ],
      ),
    );
  }
}
