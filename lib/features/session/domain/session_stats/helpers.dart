part of 'session_stats.dart';

_ChangeSummary _extractPatchSummary(String? text) {
  if (text == null || text.trim().isEmpty) {
    return const _ChangeSummary();
  }
  final looksLikePatch = text.contains('@@') ||
      text.contains('*** Begin Patch') ||
      text.contains('diff --git') ||
      text.contains('+++ ') ||
      text.contains('--- ');
  if (!looksLikePatch) {
    return const _ChangeSummary();
  }
  var added = 0;
  var removed = 0;
  for (final line in text.split('\n')) {
    if (line.startsWith('+++') || line.startsWith('---')) {
      continue;
    }
    if (line.startsWith('+')) {
      added += 1;
    } else if (line.startsWith('-')) {
      removed += 1;
    }
  }
  if (added == 0 && removed == 0) {
    return const _ChangeSummary();
  }
  return _ChangeSummary(
      changedLines: added + removed, addedLines: added, removedLines: removed);
}

_ChangeSummary _extractReplacementSummary(String original, String modified) {
  final originalLines = original.split('\n');
  final modifiedLines = modified.split('\n');
  final maxLength = originalLines.length > modifiedLines.length
      ? originalLines.length
      : modifiedLines.length;
  var added = 0;
  var removed = 0;
  for (var index = 0; index < maxLength; index += 1) {
    final oldLine = index < originalLines.length ? originalLines[index] : null;
    final newLine = index < modifiedLines.length ? modifiedLines[index] : null;
    if (oldLine == newLine) {
      continue;
    }
    if (oldLine != null) {
      removed += 1;
    }
    if (newLine != null) {
      added += 1;
    }
  }
  return _ChangeSummary(
      changedLines: added + removed, addedLines: added, removedLines: removed);
}

Map<String, dynamic>? _deepMap(
    Map<String, dynamic>? source, List<String> path) {
  dynamic current = source;
  for (final key in path) {
    if (current is! Map) {
      return null;
    }
    current = current[key];
  }
  if (current is Map<String, dynamic>) {
    return current;
  }
  if (current is Map) {
    return current.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

int? _deepInt(Map<String, dynamic>? source, List<String> path) {
  dynamic current = source;
  for (final key in path) {
    if (current is! Map) {
      return null;
    }
    current = current[key];
  }
  return _asInt(current);
}

int? _asInt(dynamic value) {
  if (value is int && value > 0) {
    return value;
  }
  if (value is double && value > 0) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

int? _firstPositive(List<int?> values) {
  for (final value in values) {
    if (value != null && value > 0) {
      return value;
    }
  }
  return null;
}

String? _firstString(List<dynamic> values) {
  for (final value in values) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

class _ChangeSummary {
  const _ChangeSummary({
    this.changedLines,
    this.addedLines,
    this.removedLines,
  });

  final int? changedLines;
  final int? addedLines;
  final int? removedLines;
}
