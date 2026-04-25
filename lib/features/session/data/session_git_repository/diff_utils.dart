part of 'session_git_repository.dart';

String? _extractDiff(ToolInfo tool) {
  final arguments = tool.arguments;
  final directPatch = arguments['patch'] ?? arguments['diff'];
  if (directPatch is String && directPatch.trim().isNotEmpty) {
    return directPatch.trimRight();
  }

  final oldString = arguments['old_string'] ?? arguments['oldText'];
  final newString = arguments['new_string'] ?? arguments['newText'];
  if (oldString is String && newString is String) {
    return _buildUnifiedDiff(
      path: _extractPrimaryPath(arguments) ?? 'untitled',
      oldContent: oldString,
      newContent: newString,
    );
  }

  final edits = arguments['edits'];
  if (edits is! List || edits.isEmpty) {
    final result = tool.result;
    if (result != null &&
        (result.contains('@@') ||
            result.contains('diff --git') ||
            result.contains('*** Begin Patch'))) {
      return result.trimRight();
    }
    return null;
  }

  final buffer = StringBuffer();
  for (final edit in edits.whereType<Map>()) {
    final patch = _buildUnifiedDiff(
      path: edit['path']?.toString() ??
          edit['file_path']?.toString() ??
          _extractPrimaryPath(arguments) ??
          'untitled',
      oldContent: edit['old_string']?.toString() ?? '',
      newContent: edit['new_string']?.toString() ?? '',
    );
    if (patch == null) {
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(patch);
  }

  if (buffer.isNotEmpty) {
    return buffer.toString().trimRight();
  }
  return null;
}

String? _extractPathFromDiff(String diff) {
  for (final line in diff.split('\n')) {
    if (line.startsWith('+++ b/')) {
      return line.substring(6).trim();
    }
    if (line.startsWith('--- a/')) {
      return line.substring(6).trim();
    }
  }
  return null;
}

(int, int) _countDiffLines(String? diff) {
  if (diff == null || diff.trim().isEmpty) {
    return (0, 0);
  }
  var added = 0;
  var removed = 0;
  for (final line in diff.split('\n')) {
    if (line.startsWith('+++') || line.startsWith('---')) {
      continue;
    }
    if (line.startsWith('+')) {
      added += 1;
    } else if (line.startsWith('-')) {
      removed += 1;
    }
  }
  return (added, removed);
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

  final maxLength = math.max(oldLines.length, newLines.length);
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
