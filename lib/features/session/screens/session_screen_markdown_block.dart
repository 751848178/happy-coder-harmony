part of 'session_screen.dart';

enum _MarkdownBlockType { text, code, table }

class _MarkdownBlock {
  const _MarkdownBlock._({
    required this.type,
    this.text = '',
    this.language = '',
    this.headers = const [],
    this.rows = const [],
  });

  final _MarkdownBlockType type;
  final String text;
  final String language;
  final List<String> headers;
  final List<List<String>> rows;

  static List<_MarkdownBlock> parse(String input) {
    final normalized = input.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final blocks = <_MarkdownBlock>[];
    final textBuffer = StringBuffer();

    void flushText() {
      final value = textBuffer.toString().trim();
      if (value.isNotEmpty) {
        final segments = value
            .split(RegExp(r'\n\s*\n'))
            .map((segment) => segment.trim())
            .where((segment) => segment.isNotEmpty);
        for (final segment in segments) {
          final detectedLanguage = _looksLikeMarkdownContentValue(segment)
              ? ''
              : _detectStructuredLanguage(segment);
          if (detectedLanguage.isNotEmpty && segment.split('\n').length >= 2) {
            blocks.add(_MarkdownBlock._(
              type: _MarkdownBlockType.code,
              text: segment,
              language: detectedLanguage,
            ));
            continue;
          }
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.text,
            text: segment,
          ));
        }
      }
      textBuffer.clear();
    }

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final fence = RegExp(r'^\s*```([^\n`]*)\s*$').firstMatch(line);
      if (fence != null) {
        flushText();
        final language = (fence.group(1) ?? '').trim();
        index += 1;
        final codeLines = <String>[];
        while (index < lines.length &&
            !RegExp(r'^\s*```\s*$').hasMatch(lines[index])) {
          codeLines.add(lines[index]);
          index += 1;
        }
        if (index < lines.length) {
          index += 1;
        }
        final code = codeLines.join('\n').trimRight();
        if (code.isNotEmpty) {
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.code,
            text: code,
            language: language,
          ));
        }
        continue;
      }

      if (_isMarkdownTableStart(lines, index)) {
        flushText();
        final headers = _splitMarkdownTableRow(lines[index]);
        index += 2;
        final rows = <List<String>>[];
        while (
            index < lines.length && _looksLikeMarkdownTableRow(lines[index])) {
          rows.add(_splitMarkdownTableRow(lines[index]));
          index += 1;
        }
        if (headers.isNotEmpty) {
          blocks.add(_MarkdownBlock._(
            type: _MarkdownBlockType.table,
            headers: headers,
            rows: rows,
          ));
        }
        continue;
      }

      textBuffer.writeln(line);
      index += 1;
    }

    flushText();
    return blocks.isEmpty
        ? [
            _MarkdownBlock._(
              type: _MarkdownBlockType.text,
              text: normalized,
            ),
          ]
        : blocks;
  }

  static bool _isMarkdownTableStart(List<String> lines, int index) {
    if (index + 1 >= lines.length) {
      return false;
    }
    final headerLine = lines[index];
    final separatorLine = lines[index + 1];
    return _looksLikeMarkdownTableRow(headerLine) &&
        RegExp(r'^\s*\|?(\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?\s*$')
            .hasMatch(separatorLine);
  }

  static bool _looksLikeMarkdownTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') &&
        !trimmed.startsWith('```') &&
        trimmed.replaceAll('|', '').trim().isNotEmpty;
  }

  static List<String> _splitMarkdownTableRow(String line) {
    final trimmed = line.trim().replaceFirst(RegExp(r'^\|'), '').replaceFirst(
          RegExp(r'\|$'),
          '',
        );
    return trimmed.split('|').map((cell) => cell.trim()).toList();
  }
}

