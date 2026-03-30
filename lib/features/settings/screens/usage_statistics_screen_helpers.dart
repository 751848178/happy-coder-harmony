part of 'usage_statistics_screen.dart';

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

extension _UsageStatisticsScreenHelpers on _UsageStatisticsScreenState {
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
