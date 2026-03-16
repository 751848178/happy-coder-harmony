part of 'usage_statistics_screen.dart';

extension _UsageStatisticsScreenMockData on _UsageStatisticsScreenState {
  UsageStatistics _buildMockStatistics() {
    final now = DateTime.now();
    return UsageStatistics(
      totalSessions: 42,
      totalMessages: 1234,
      totalTokens: 567890,
      totalCost: 12.34,
      totalFilesAccessed: 89,
      totalToolsUsed: 156,
      firstSessionDate: DateTime(2026, 2, 1),
      lastSessionDate: now,
      daysActive: 28,
      dailyUsage: _buildMockDailyUsage(),
      toolsUsage: {
        'Bash': 45,
        'Edit': 32,
        'Write': 28,
        'Glob': 15,
        'Grep': 12,
        'Read': 24,
      },
      modelUsage: {
        'Claude 3.5 Sonnet': 56,
        'Claude 3 Opus': 32,
        'Claude 3 Haiku': 18,
      },
    );
  }

  List<DailyUsage> _buildMockDailyUsage() {
    final now = DateTime.now();
    final result = <DailyUsage>[];
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final weekdayMessages =
          date.weekday >= 1 && date.weekday <= 5 ? 10 + (i % 20) : 5 + (i % 10);
      result.add(
        DailyUsage(
          date: date,
          messages: weekdayMessages,
          tokens: weekdayMessages * (100 + (i % 50)),
          sessions: (weekdayMessages / 5).ceil(),
        ),
      );
    }
    return result;
  }
}
