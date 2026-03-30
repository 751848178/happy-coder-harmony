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

  static List<_MarkdownTextSection> parse(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return const [];
    }

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
