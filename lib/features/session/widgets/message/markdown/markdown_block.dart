import '../content_detection.dart';

enum MarkdownBlockType { text, code, table }

class MarkdownBlock {
  static final Map<String, List<MarkdownBlock>> parseCache =
      <String, List<MarkdownBlock>>{};
  static final RegExp _paragraphSplitPattern = RegExp(r'\n\s*\n');
  static final RegExp _fenceStartPattern = RegExp(r'^\s*```([^\n`]*)\s*$');
  static final RegExp _fenceEndPattern = RegExp(r'^\s*```\s*$');
  static final RegExp _tableSeparatorPattern =
      RegExp(r'^\s*\|?(\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?\s*$');
  static final RegExp _leadingPipePattern = RegExp(r'^\|');
  static final RegExp _trailingPipePattern = RegExp(r'\|$');
  static const int _maxCacheEntries = 120;

  const MarkdownBlock._({
    required this.type,
    this.text = '',
    this.language = '',
    this.headers = const [],
    this.rows = const [],
  });

  final MarkdownBlockType type;
  final String text;
  final String language;
  final List<String> headers;
  final List<List<String>> rows;

  static List<MarkdownBlock> parse(String input) {
    final cached = parseCache[input];
    if (cached != null) return cached;

    final normalized = input.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final blocks = <MarkdownBlock>[];
    final textBuffer = StringBuffer();

    void flushText() {
      final value = textBuffer.toString().trim();
      if (value.isNotEmpty) {
        final segments = value
            .split(_paragraphSplitPattern)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        for (final segment in segments) {
          final detected = looksLikeMarkdownContent(segment)
              ? ''
              : detectStructuredLanguage(segment);
          if (detected.isNotEmpty && segment.split('\n').length >= 2) {
            blocks.add(MarkdownBlock._(
                type: MarkdownBlockType.code,
                text: segment,
                language: detected));
            continue;
          }
          blocks.add(
              MarkdownBlock._(type: MarkdownBlockType.text, text: segment));
        }
      }
      textBuffer.clear();
    }

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final fence = _fenceStartPattern.firstMatch(line);
      if (fence != null) {
        flushText();
        final language = (fence.group(1) ?? '').trim();
        index += 1;
        final codeLines = <String>[];
        while (
            index < lines.length && !_fenceEndPattern.hasMatch(lines[index])) {
          codeLines.add(lines[index]);
          index += 1;
        }
        if (index < lines.length) index += 1;
        final code = codeLines.join('\n').trimRight();
        if (code.isNotEmpty) {
          blocks.add(MarkdownBlock._(
              type: MarkdownBlockType.code, text: code, language: language));
        }
        continue;
      }

      if (_isTableStart(lines, index)) {
        flushText();
        final hdrs = _splitRow(lines[index]);
        index += 2;
        final rows = <List<String>>[];
        while (index < lines.length && _looksLikeRow(lines[index])) {
          rows.add(_splitRow(lines[index]));
          index += 1;
        }
        if (hdrs.isNotEmpty) {
          blocks.add(MarkdownBlock._(
              type: MarkdownBlockType.table, headers: hdrs, rows: rows));
        }
        continue;
      }

      textBuffer.writeln(line);
      index += 1;
    }

    flushText();
    final resolved = blocks.isEmpty
        ? [MarkdownBlock._(type: MarkdownBlockType.text, text: normalized)]
        : blocks;
    if (parseCache.length >= _maxCacheEntries) {
      parseCache.remove(parseCache.keys.first);
    }
    return parseCache[input] = List<MarkdownBlock>.unmodifiable(resolved);
  }

  static bool _isTableStart(List<String> lines, int index) {
    if (index + 1 >= lines.length) return false;
    return _looksLikeRow(lines[index]) &&
        _tableSeparatorPattern.hasMatch(lines[index + 1]);
  }

  static bool _looksLikeRow(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') &&
        !trimmed.startsWith('```') &&
        trimmed.replaceAll('|', '').trim().isNotEmpty;
  }

  static List<String> _splitRow(String line) {
    final trimmed = line
        .trim()
        .replaceFirst(_leadingPipePattern, '')
        .replaceFirst(_trailingPipePattern, '');
    return trimmed.split('|').map((c) => c.trim()).toList();
  }
}
