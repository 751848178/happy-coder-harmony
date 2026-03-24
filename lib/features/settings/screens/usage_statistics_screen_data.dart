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

  Iterable<Map<String, dynamic>?> _sessionUsageCandidates(
      Session session) sync* {
    yield session.metadata;
    yield _deepMap(session.metadata, const ['summary']);
    yield _deepMap(session.metadata, const ['stats']);
    yield session.agentState;
    yield _deepMap(session.agentState, const ['summary']);
    yield _deepMap(session.agentState, const ['stats']);
  }

  int _resolveSessionTokenCount(Session session) {
    return _firstNonNegativeInt([
          session.latestUsage?.tokenCount,
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['tokenCount']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['token_count']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['inputTokens']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['outputTokens']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['contextSize']),
        ]) ??
        0;
  }

  int _resolveSessionFilesAccessed(Session session) {
    return _firstNonNegativeInt([
          session.latestUsage?.filesAccessed,
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['filesAccessed']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['files_accessed']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['cacheRead']),
        ]) ??
        0;
  }

  int _resolveSessionToolsUsed(Session session) {
    return _firstNonNegativeInt([
          session.latestUsage?.toolsUsed,
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['toolsUsed']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['tools_used']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['toolCallCount']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['tool_call_count']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepInt(candidate, const ['cacheCreation']),
        ]) ??
        0;
  }

  double _resolveSessionCost(Session session) {
    return _firstNonNegativeDouble([
          for (final candidate in _sessionUsageCandidates(session))
            _deepDouble(candidate, const ['cost']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepDouble(candidate, const ['totalCost']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepDouble(candidate, const ['total_cost']),
          for (final candidate in _sessionUsageCandidates(session))
            _deepDouble(candidate, const ['estimatedCost']),
        ]) ??
        0;
  }

  String _resolveSessionModel(Session session) {
    return _firstNonEmptyString([
          session.modelMode,
          session.metadata?['currentModelCode'],
          session.metadata?['modelMode'],
          session.metadata?['model'],
          session.agentState?['model'],
          session.agentState?['modelName'],
        ]) ??
        '未标记模型';
  }
}

class _DailyUsageAccumulator {
  int messages = 0;
  int tokens = 0;
  int sessions = 0;
}

int? _firstNonNegativeInt(List<int?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate >= 0) {
      return candidate;
    }
  }
  return null;
}

double? _firstNonNegativeDouble(List<double?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate >= 0) {
      return candidate;
    }
  }
  return null;
}

String? _firstNonEmptyString(List<Object?> candidates) {
  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _deepMap(
  Map<String, dynamic>? source,
  List<String> path,
) {
  dynamic current = source;
  for (final key in path) {
    if (current is! Map<String, dynamic>) {
      return null;
    }
    current = current[key];
    if (current is Map && current is! Map<String, dynamic>) {
      current = current.map(
        (mapKey, value) => MapEntry(mapKey.toString(), value),
      );
    }
  }
  return current is Map<String, dynamic> ? current : null;
}

int? _deepInt(Map<String, dynamic>? source, List<String> path) {
  final value = _deepValue(source, path);
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _deepDouble(Map<String, dynamic>? source, List<String> path) {
  final value = _deepValue(source, path);
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

dynamic _deepValue(Map<String, dynamic>? source, List<String> path) {
  dynamic current = source;
  for (final key in path) {
    if (current is! Map<String, dynamic>) {
      return null;
    }
    current = current[key];
    if (current is Map && current is! Map<String, dynamic>) {
      current = current.map(
        (mapKey, value) => MapEntry(mapKey.toString(), value),
      );
    }
  }
  return current;
}
