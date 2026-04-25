part of 'usage_statistics_screen.dart';

extension _UsageStatisticsScreenData on _UsageStatisticsScreenState {
  UsageStatistics _buildStatisticsFromSessions(
    SessionServiceNotifier sessionNotifier,
  ) {
    final sessions = [...sessionNotifier.sessions]
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final now = DateTime.now();
    if (sessions.isEmpty) {
      return UsageStatistics(
        totalSessions: 0,
        totalMessages: 0,
        totalTokens: 0,
        totalCost: 0,
        totalFilesAccessed: 0,
        totalToolsUsed: 0,
        firstSessionDate: now,
        lastSessionDate: now,
        daysActive: 0,
        dailyUsage: const <DailyUsage>[],
        toolsUsage: const <String, int>{},
        modelUsage: const <String, int>{},
      );
    }

    final dailyBuckets = <DateTime, _DailyUsageAccumulator>{};
    final toolUsage = <String, int>{};
    final modelUsage = <String, int>{};
    final activeDays = <DateTime>{};

    var totalMessages = 0;
    var totalTokens = 0;
    var totalFilesAccessed = 0;
    var totalToolsUsed = 0;
    var totalCost = 0.0;

    for (final session in sessions) {
      final messages = sessionNotifier.getSessionMessages(session.id)?.messages;
      final stats = SessionStatsCalculator.fromSession(
        session: session,
        messages: messages,
      );
      final messageCount = stats.messageCount;
      final tokenCount = _resolveSessionTokenCount(session);
      final filesAccessed = _resolveSessionFilesAccessed(session);
      final recordedToolCount = _resolveSessionToolsUsed(session);
      final sessionCost = _resolveSessionCost(session);

      totalMessages += messageCount;
      totalTokens += tokenCount;
      totalFilesAccessed += filesAccessed;
      totalCost += sessionCost;

      final dayKey = DateTime(
        session.updatedAt.year,
        session.updatedAt.month,
        session.updatedAt.day,
      );
      activeDays.add(dayKey);
      final daily =
          dailyBuckets.putIfAbsent(dayKey, _DailyUsageAccumulator.new);
      daily
        ..messages += messageCount
        ..tokens += tokenCount
        ..sessions += 1;

      final modelKey = _resolveSessionModel(session);
      modelUsage.update(modelKey, (value) => value + 1, ifAbsent: () => 1);

      var namedToolCount = 0;
      if (messages != null) {
        for (final message in messages) {
          final toolName = message.tool?.name.trim();
          if (toolName == null || toolName.isEmpty) {
            continue;
          }
          namedToolCount++;
          toolUsage.update(toolName, (value) => value + 1, ifAbsent: () => 1);
        }
      }
      final effectiveToolCount = namedToolCount > recordedToolCount
          ? namedToolCount
          : recordedToolCount;
      totalToolsUsed += effectiveToolCount;
      final uncategorizedToolCount = effectiveToolCount - namedToolCount;
      if (uncategorizedToolCount > 0) {
        toolUsage.update(
          '其他工具',
          (value) => value + uncategorizedToolCount,
          ifAbsent: () => uncategorizedToolCount,
        );
      }
    }

    final dailyUsage = dailyBuckets.entries
        .map(
          (entry) => DailyUsage(
            date: entry.key,
            messages: entry.value.messages,
            tokens: entry.value.tokens,
            sessions: entry.value.sessions,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return UsageStatistics(
      totalSessions: sessions.length,
      totalMessages: totalMessages,
      totalTokens: totalTokens,
      totalCost: totalCost,
      totalFilesAccessed: totalFilesAccessed,
      totalToolsUsed: totalToolsUsed,
      firstSessionDate: sessions.first.createdAt,
      lastSessionDate: sessions.last.updatedAt,
      daysActive: activeDays.length,
      dailyUsage: dailyUsage,
      toolsUsage: toolUsage,
      modelUsage: modelUsage,
    );
  }
}
