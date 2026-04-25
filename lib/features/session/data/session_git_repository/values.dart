part of 'session_git_repository.dart';

String _normalizePath(String path) {
  var normalized = path.trim().replaceAll('\\', '/');
  if (normalized.startsWith('a/')) {
    normalized = normalized.substring(2);
  } else if (normalized.startsWith('b/')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  return normalized;
}

String _fileName(String path) {
  final normalized = _normalizePath(path);
  final segments = normalized.split('/');
  return segments.isEmpty ? normalized : segments.last;
}

SessionGitFileStatus _parseStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'added':
    case 'a':
      return SessionGitFileStatus.added;
    case 'deleted':
    case 'd':
      return SessionGitFileStatus.deleted;
    case 'renamed':
    case 'r':
      return SessionGitFileStatus.renamed;
    case 'untracked':
    case 'u':
    case '?':
      return SessionGitFileStatus.untracked;
    default:
      return SessionGitFileStatus.modified;
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

int? _firstPositive(List<int?> values) {
  for (final value in values) {
    if (value != null && value >= 0) {
      return value;
    }
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String? _stringValue(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}
