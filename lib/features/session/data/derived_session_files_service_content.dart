part of 'derived_session_files_service.dart';

String? _extractToolContentForPath(
  ToolInfo tool,
  String normalizedTarget, {
  String? rootPath,
}) {
  final arguments = tool.arguments;
  final hasPathMatch = _extractToolPaths(tool).any(
    (candidate) => _pathsMatch(candidate, normalizedTarget, rootPath: rootPath),
  );
  final directContent = _firstNonEmpty([
    _stringValue(arguments['content']),
    _stringValue(arguments['text']),
    _stringValue(arguments['new_string']),
    _stringValue(arguments['newText']),
  ]);
  if (hasPathMatch && directContent != null) {
    return directContent;
  }
  final edits = arguments['edits'];
  if (edits is List) {
    for (final edit in edits.reversed.whereType<Map>()) {
      final map = _asMap(edit);
      final path = _firstNonEmpty([
        map?['path']?.toString(),
        map?['file_path']?.toString(),
        map?['target_file']?.toString(),
      ]);
      if (!_pathsMatch(path, normalizedTarget, rootPath: rootPath)) {
        continue;
      }
      final content = _firstNonEmpty([
        map?['new_string']?.toString(),
        map?['newText']?.toString(),
      ]);
      if (content != null) {
        return content;
      }
    }
  }
  final diff = _extractDiff(tool);
  if (diff != null &&
      _extractPathsFromDiff(diff).any(
        (candidate) => _pathsMatch(
          candidate,
          normalizedTarget,
          rootPath: rootPath,
        ),
      )) {
    return diff;
  }
  if (_looksLikeReadableResult(tool.name) &&
      tool.result != null &&
      tool.result!.trim().isNotEmpty &&
      hasPathMatch) {
    return tool.result!.trimRight();
  }
  if (tool.name.toLowerCase() == 'file' &&
      tool.result != null &&
      tool.result!.trim().isNotEmpty &&
      hasPathMatch) {
    return tool.result!.trimRight();
  }
  return null;
}

String? _extractDiff(ToolInfo tool) {
  final arguments = tool.arguments;
  final directPatch = arguments['patch'] ?? arguments['diff'];
  if (directPatch is String && directPatch.trim().isNotEmpty) {
    return directPatch.trimRight();
  }
  final oldString = _stringValue(arguments['old_string']) ??
      _stringValue(arguments['oldText']);
  final newString = _stringValue(arguments['new_string']) ??
      _stringValue(arguments['newText']);
  final path = _firstNonEmpty([
    _stringValue(arguments['file_path']),
    _stringValue(arguments['path']),
    _stringValue(arguments['target_file']),
  ]);
  if (path != null && (oldString != null || newString != null)) {
    return _buildUnifiedDiff(
      path: path,
      oldContent: oldString,
      newContent: newString,
    );
  }
  final result = tool.result;
  if (result != null &&
      (result.contains('@@') ||
          result.contains('diff --git') ||
          result.contains('*** Begin Patch'))) {
    return result.trimRight();
  }
  return null;
}

String? _buildUnifiedDiff({
  required String path,
  String? oldContent,
  String? newContent,
}) {
  if ((oldContent == null || oldContent.isEmpty) &&
      (newContent == null || newContent.isEmpty)) {
    return null;
  }
  final oldLines = oldContent?.split('\n') ?? const <String>[];
  final newLines = newContent?.split('\n') ?? const <String>[];
  final buffer = StringBuffer()
    ..writeln('diff --git a/$path b/$path')
    ..writeln('--- ${oldContent == null ? '/dev/null' : 'a/$path'}')
    ..writeln('+++ ${newContent == null ? '/dev/null' : 'b/$path'}')
    ..writeln('@@ -1,${oldLines.length} +1,${newLines.length} @@');
  final maxLength =
      oldLines.length > newLines.length ? oldLines.length : newLines.length;
  for (var index = 0; index < maxLength; index += 1) {
    final oldLine = index < oldLines.length ? oldLines[index] : null;
    final newLine = index < newLines.length ? newLines[index] : null;
    if (oldLine == newLine) {
      if (oldLine != null) {
        buffer.writeln(' $oldLine');
      }
      continue;
    }
    if (oldLine != null) {
      buffer.writeln('-$oldLine');
    }
    if (newLine != null) {
      buffer.writeln('+$newLine');
    }
  }
  return buffer.toString().trimRight();
}

bool _looksLikeReadableResult(String toolName) {
  final lowerTool = toolName.toLowerCase();
  return lowerTool.contains('read') ||
      lowerTool.contains('cat') ||
      lowerTool.contains('open') ||
      lowerTool.contains('view');
}
