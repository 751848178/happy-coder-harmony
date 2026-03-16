part of 'session_git_diff_screen.dart';

List<_PatchLine> parseSessionGitPatch(String patch) {
  if (patch.trim().isEmpty) {
    return const [];
  }

  final result = <_PatchLine>[];
  var left = 0;
  var right = 0;
  final hunkPattern = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

  for (final rawLine in patch.split('\n')) {
    if (rawLine.startsWith('diff --git') ||
        rawLine.startsWith('index ') ||
        rawLine.startsWith('--- ') ||
        rawLine.startsWith('+++ ')) {
      result.add(_PatchLine.meta(rawLine));
      continue;
    }

    final hunkMatch = hunkPattern.firstMatch(rawLine);
    if (hunkMatch != null) {
      left = int.tryParse(hunkMatch.group(1) ?? '') ?? 0;
      right = int.tryParse(hunkMatch.group(2) ?? '') ?? 0;
      result.add(_PatchLine.header(rawLine));
      continue;
    }

    if (rawLine.startsWith('+')) {
      result.add(
        _PatchLine.added(content: rawLine.substring(1), rightNumber: right),
      );
      right += 1;
      continue;
    }

    if (rawLine.startsWith('-')) {
      result.add(
        _PatchLine.removed(content: rawLine.substring(1), leftNumber: left),
      );
      left += 1;
      continue;
    }

    result.add(
      _PatchLine.context(
        content: rawLine.startsWith(' ') ? rawLine.substring(1) : rawLine,
        leftNumber: left == 0 ? null : left,
        rightNumber: right == 0 ? null : right,
      ),
    );
    if (!rawLine.startsWith('\\')) {
      left += 1;
      right += 1;
    }
  }

  return result;
}

Color patchBackgroundColor(_PatchLineType type) {
  switch (type) {
    case _PatchLineType.added:
      return const Color(0xFF052E16);
    case _PatchLineType.removed:
      return const Color(0xFF3F0D12);
    case _PatchLineType.header:
      return const Color(0xFF1E293B);
    case _PatchLineType.meta:
      return const Color(0xFF111827);
    case _PatchLineType.context:
      return const Color(0xFF0F172A);
  }
}

Color patchForegroundColor(_PatchLineType type) {
  switch (type) {
    case _PatchLineType.added:
      return const Color(0xFF86EFAC);
    case _PatchLineType.removed:
      return const Color(0xFFFDA4AF);
    case _PatchLineType.header:
      return const Color(0xFFBFDBFE);
    case _PatchLineType.meta:
      return const Color(0xFF94A3B8);
    case _PatchLineType.context:
      return const Color(0xFFE5E7EB);
  }
}
