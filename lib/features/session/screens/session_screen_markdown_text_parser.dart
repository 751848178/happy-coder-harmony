part of 'session_screen.dart';

class _MarkdownTextSection {
  const _MarkdownTextSection._({
    required this.type,
    this.text = '',
    this.items = const [],
  });

  final _MarkdownTextSectionType type;
  final String text;
  final List<String> items;

  // LRU cache keyed by raw input — same pattern as _MarkdownBlock.parse().
  // Without this, every _MarkdownTextBlock entering the viewport re-runs
  // multiple regex splits (chunks, heading, bullet, numbered, quote).
  static final Map<String, List<_MarkdownTextSection>> _parseCache =
      <String, List<_MarkdownTextSection>>{};
  static const int _maxCacheEntries = 120;

  static List<_MarkdownTextSection> parse(String input) {
    final cached = _parseCache[input];
    if (cached != null) {
      return cached;
    }

    final result = _parseImpl(input);

    if (_parseCache.length >= _maxCacheEntries) {
      _parseCache.remove(_parseCache.keys.first);
    }
    return _parseCache[input] = result;
  }

  static List<_MarkdownTextSection> _parseImpl(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    return _computeSections(normalized);
  }

  static List<_MarkdownTextSection> _computeSections(String normalized) {

    final chunks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty);
    final sections = <_MarkdownTextSection>[];

    for (final chunk in chunks) {
      final lines = chunk.split('\n').map((line) => line.trimRight()).toList();
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(lines.first);
      if (heading != null && lines.length == 1) {
        final level = heading.group(1)!.length;
        final text = heading.group(2)!.trim();
        sections.add(
          _MarkdownTextSection._(
            type: switch (level) {
              1 => _MarkdownTextSectionType.heading1,
              2 => _MarkdownTextSectionType.heading2,
              _ => _MarkdownTextSectionType.heading3,
            },
            text: text,
          ),
        );
        continue;
      }

      if (lines.every((line) => RegExp(r'^\s*[-*+]\s+').hasMatch(line))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.bulletList,
            items: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*[-*+]\s+'), ''))
                .toList(),
          ),
        );
        continue;
      }

      if (lines.every((line) => RegExp(r'^\s*\d+\.\s+').hasMatch(line))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.numberedList,
            items: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*\d+\.\s+'), ''))
                .toList(),
          ),
        );
        continue;
      }

      if (lines.every((line) => line.trimLeft().startsWith('>'))) {
        sections.add(
          _MarkdownTextSection._(
            type: _MarkdownTextSectionType.quote,
            text: lines
                .map((line) => line.replaceFirst(RegExp(r'^\s*>\s?'), ''))
                .join('\n')
                .trim(),
          ),
        );
        continue;
      }

      sections.add(
        _MarkdownTextSection._(
          type: _MarkdownTextSectionType.paragraph,
          text: chunk,
        ),
      );
    }

    return sections;
  }
}
