part of 'session_git_repository.dart';

void _mergeChange(
  Map<String, _MutableGitFile> changes,
  _MutableGitFile incoming,
) {
  final existing = changes[incoming.path];
  if (existing == null) {
    changes[incoming.path] = incoming;
    return;
  }
  existing.merge(incoming);
}

int _compareFiles(SessionGitFile a, SessionGitFile b) {
  final updatedCompare = (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
      .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
  if (updatedCompare != 0) {
    return updatedCompare;
  }
  return a.path.compareTo(b.path);
}

Map<String, String> _buildFileIndex(
  List<SessionFile> files, {
  required String rootPath,
}) {
  final result = <String, String>{};
  for (final file in files) {
    final normalized = _normalizePath(file.filePath);
    result[normalized] = file.id;
    result.putIfAbsent(_fileName(normalized), () => file.id);
    if (rootPath.isNotEmpty && normalized.startsWith('$rootPath/')) {
      result.putIfAbsent(
        normalized.substring(rootPath.length + 1),
        () => file.id,
      );
    } else if (rootPath.isNotEmpty && !normalized.startsWith('/')) {
      result.putIfAbsent('$rootPath/$normalized', () => file.id);
    }
  }
  return result;
}

String? _lookupFileId(Map<String, String> fileIdsByPath, String path) {
  return fileIdsByPath[_normalizePath(path)] ?? fileIdsByPath[_fileName(path)];
}

String _resolveRootPath(Session session) {
  return _firstNonEmpty(
          [_stringValue(session.metadata?['path']), session.path]) ??
      '';
}

String? _resolveBranch(Session session) {
  for (final source in [session.metadata, session.agentState]) {
    final branch = _searchString(
      source,
      const {'branch', 'branchName', 'currentBranch', 'gitBranch'},
    );
    if (branch != null) {
      return branch;
    }
  }
  return null;
}

String? _searchString(
  dynamic value,
  Set<String> keys, {
  int depth = 0,
}) {
  if (depth > 4) {
    return null;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (keys.contains(entry.key.toString())) {
        final text = _stringValue(entry.value);
        if (text != null) {
          return text;
        }
      }
    }
    for (final nested in value.values) {
      final result = _searchString(nested, keys, depth: depth + 1);
      if (result != null) {
        return result;
      }
    }
  }
  if (value is List) {
    for (final nested in value) {
      final result = _searchString(nested, keys, depth: depth + 1);
      if (result != null) {
        return result;
      }
    }
  }
  return null;
}

DateTime? _latestUpdatedAt(List<SessionGitFile> files) {
  DateTime? latest;
  for (final file in files) {
    final updatedAt = file.updatedAt;
    if (updatedAt == null) {
      continue;
    }
    if (latest == null || updatedAt.isAfter(latest)) {
      latest = updatedAt;
    }
  }
  return latest;
}
