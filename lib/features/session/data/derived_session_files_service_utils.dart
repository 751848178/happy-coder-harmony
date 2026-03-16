part of 'derived_session_files_service.dart';

bool _pathsMatch(
  String? candidate,
  String target, {
  String? rootPath,
}) {
  final normalizedCandidate = _normalizePath(candidate);
  if (normalizedCandidate == null) {
    return false;
  }
  if (normalizedCandidate == target) {
    return true;
  }
  if (rootPath != null && rootPath.isNotEmpty) {
    if (normalizedCandidate == '$rootPath/$target' ||
        target == '$rootPath/$normalizedCandidate') {
      return true;
    }
    if (target.startsWith('$rootPath/') &&
        normalizedCandidate == target.substring(rootPath.length + 1)) {
      return true;
    }
    if (normalizedCandidate.startsWith('$rootPath/') &&
        target == normalizedCandidate.substring(rootPath.length + 1)) {
      return true;
    }
  }
  return _fileName(normalizedCandidate) == _fileName(target);
}

bool _shouldIgnorePath(String path, {String? rootPath}) {
  if (path.isEmpty ||
      path == '/dev/null' ||
      path == 'untitled' ||
      path == '.' ||
      path.endsWith('/')) {
    return true;
  }
  return rootPath != null && path == rootPath;
}

String? _normalizePath(String? rawPath) {
  if (rawPath == null) {
    return null;
  }
  final trimmed = rawPath.trim();
  final decoded = () {
    try {
      return Uri.decodeComponent(trimmed);
    } catch (_) {
      return trimmed;
    }
  }();
  var normalized = decoded.replaceAll('\\', '/').replaceAll('file://', '');
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.startsWith('a/')) {
    normalized = normalized.substring(2);
  } else if (normalized.startsWith('b/')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith('"') && normalized.endsWith('"')) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  return normalized.isEmpty ? null : normalized;
}

String _fileName(String path) {
  final normalized = _normalizePath(path) ?? path;
  final segments = normalized.split('/');
  return segments.isEmpty ? normalized : segments.last;
}

String? _guessMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
    return 'text/markdown';
  }
  if (lower.endsWith('.json')) {
    return 'application/json';
  }
  if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
    return 'application/yaml';
  }
  if (lower.endsWith('.dart') ||
      lower.endsWith('.js') ||
      lower.endsWith('.ts') ||
      lower.endsWith('.tsx') ||
      lower.endsWith('.jsx') ||
      lower.endsWith('.py') ||
      lower.endsWith('.go') ||
      lower.endsWith('.java') ||
      lower.endsWith('.kt') ||
      lower.endsWith('.swift') ||
      lower.endsWith('.sh') ||
      lower.endsWith('.zsh') ||
      lower.endsWith('.bash')) {
    return 'text/plain';
  }
  return null;
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

String? _stringValue(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
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
