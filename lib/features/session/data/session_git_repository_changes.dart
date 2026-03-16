part of 'session_git_repository.dart';

_MutableGitFile? _parseFileOperation(
  FileOperation operation, {
  required Map<String, String> fileIdsByPath,
}) {
  if (operation.operation == FileOperationType.read) {
    return null;
  }
  final rawPath = operation.filePath;
  if (rawPath == null || rawPath.trim().isEmpty) {
    return null;
  }

  final path = _normalizePath(rawPath);
  final diff = _buildUnifiedDiff(
    path: path,
    oldContent: operation.oldContent,
    newContent: operation.newContent,
  );
  final summary = _countDiffLines(diff);
  return _MutableGitFile(
    path: path,
    fileName: _fileName(path),
    status: switch (operation.operation) {
      FileOperationType.delete => SessionGitFileStatus.deleted,
      FileOperationType.write => operation.oldContent == null
          ? SessionGitFileStatus.added
          : SessionGitFileStatus.modified,
      FileOperationType.read => SessionGitFileStatus.modified,
    },
    fileId: _lookupFileId(fileIdsByPath, path),
    isStaged: false,
    addedLines: summary.$1,
    removedLines: summary.$2,
    diff: diff,
    updatedAt: operation.timestamp,
    priority: 2,
  );
}

_MutableGitFile? _parseToolChange(
  ReducerMessage message, {
  required Map<String, String> fileIdsByPath,
}) {
  final tool = message.tool;
  if (tool == null) {
    return null;
  }

  final lowerTool = tool.name.toLowerCase();
  final isChangeTool = lowerTool.contains('edit') ||
      lowerTool.contains('write') ||
      lowerTool.contains('patch') ||
      lowerTool.contains('diff');
  if (!isChangeTool) {
    return null;
  }

  final diff = _extractDiff(tool);
  final path = _firstNonEmpty([
    _extractPrimaryPath(tool.arguments),
    if (diff != null) _extractPathFromDiff(diff),
  ]);
  if (path == null) {
    return null;
  }

  final normalizedPath = _normalizePath(path);
  final oldText = _stringValue(tool.arguments['old_string']) ??
      _stringValue(tool.arguments['oldText']);
  final newText = _stringValue(tool.arguments['new_string']) ??
      _stringValue(tool.arguments['newText']);
  final summary = _countDiffLines(diff);
  return _MutableGitFile(
    path: normalizedPath,
    fileName: _fileName(normalizedPath),
    fileId: _lookupFileId(fileIdsByPath, normalizedPath),
    previousPath: _firstNonEmpty([
      _stringValue(tool.arguments['old_path']),
      _stringValue(tool.arguments['source_path']),
    ]),
    status: _inferStatus(
      toolName: lowerTool,
      diff: diff,
      oldText: oldText,
      newText: newText,
    ),
    isStaged: false,
    addedLines: summary.$1,
    removedLines: summary.$2,
    diff: diff ??
        _buildUnifiedDiff(
          path: normalizedPath,
          oldContent: oldText,
          newContent: newText,
        ),
    updatedAt: message.createdAt,
    priority: 1,
  );
}

String? _extractPrimaryPath(Map<String, dynamic> arguments) {
  const keys = ['file_path', 'path', 'cwd', 'root', 'uri', 'target_file'];
  for (final key in keys) {
    final value = arguments[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  final locations = arguments['locations'];
  if (locations is List && locations.isNotEmpty) {
    final first = locations.first;
    if (first is Map && first['path'] is String) {
      return first['path'] as String;
    }
  }
  return null;
}

SessionGitFileStatus _inferStatus({
  required String toolName,
  required String? diff,
  required String? oldText,
  required String? newText,
}) {
  if (diff != null) {
    if (diff.contains('new file mode') || diff.contains('--- /dev/null')) {
      return SessionGitFileStatus.added;
    }
    if (diff.contains('deleted file mode') || diff.contains('+++ /dev/null')) {
      return SessionGitFileStatus.deleted;
    }
    if (diff.contains('rename from') || diff.contains('rename to')) {
      return SessionGitFileStatus.renamed;
    }
  }
  if (toolName.contains('write') && (oldText == null || oldText.isEmpty)) {
    return SessionGitFileStatus.added;
  }
  return SessionGitFileStatus.modified;
}
