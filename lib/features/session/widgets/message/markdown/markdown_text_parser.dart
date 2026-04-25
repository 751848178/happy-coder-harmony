enum MarkdownTextSectionType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  quote,
  standaloneImage,
}

class MarkdownTextSection {
  const MarkdownTextSection._({
    required this.type,
    this.text = '',
    this.items = const [],
    this.imageUrl,
    this.imageAlt,
  });

  final MarkdownTextSectionType type;
  final String text;
  final List<String> items;
  final String? imageUrl;
  final String? imageAlt;

  static final Map<String, List<MarkdownTextSection>> parseCache =
      <String, List<MarkdownTextSection>>{};
  static const int _maxCacheEntries = 120;

  static List<MarkdownTextSection> parse(String input) {
    final cached = parseCache[input];
    if (cached != null) return cached;
    final result = _parseImpl(input);
    if (parseCache.length >= _maxCacheEntries) {
      parseCache.remove(parseCache.keys.first);
    }
    return parseCache[input] = result;
  }

  static List<MarkdownTextSection> _parseImpl(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) return const [];
    return _computeSections(normalized);
  }

  static List<MarkdownTextSection> _computeSections(String normalized) {
    final chunks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty);
    final sections = <MarkdownTextSection>[];

    for (final chunk in chunks) {
      final lines = chunk.split('\n').map((l) => l.trimRight()).toList();
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(lines.first);
      if (heading != null && lines.length == 1) {
        final level = heading.group(1)!.length;
        final text = heading.group(2)!.trim();
        sections.add(MarkdownTextSection._(
          type: switch (level) {
            1 => MarkdownTextSectionType.heading1,
            2 => MarkdownTextSectionType.heading2,
            _ => MarkdownTextSectionType.heading3
          },
          text: text,
        ));
        continue;
      }
      if (lines.every((l) => RegExp(r'^\s*[-*+]\s+').hasMatch(l))) {
        sections.add(MarkdownTextSection._(
          type: MarkdownTextSectionType.bulletList,
          items: lines
              .map((l) => l.replaceFirst(RegExp(r'^\s*[-*+]\s+'), ''))
              .toList(),
        ));
        continue;
      }
      if (lines.every((l) => RegExp(r'^\s*\d+\.\s+').hasMatch(l))) {
        sections.add(MarkdownTextSection._(
          type: MarkdownTextSectionType.numberedList,
          items: lines
              .map((l) => l.replaceFirst(RegExp(r'^\s*\d+\.\s+'), ''))
              .toList(),
        ));
        continue;
      }
      if (lines.every((l) => l.trimLeft().startsWith('>'))) {
        sections.add(MarkdownTextSection._(
          type: MarkdownTextSectionType.quote,
          text: lines
              .map((l) => l.replaceFirst(RegExp(r'^\s*>\s?'), ''))
              .join('\n')
              .trim(),
        ));
        continue;
      }
      final standaloneImage = _tryParseStandaloneImage(chunk);
      if (standaloneImage != null) {
        sections.addAll(standaloneImage);
        continue;
      }
      sections.add(MarkdownTextSection._(
          type: MarkdownTextSectionType.paragraph, text: chunk));
    }
    return sections;
  }

  static final RegExp _imagePattern = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
  static final RegExp _onlyImagesPattern =
      RegExp(r'^(\s*!\[[^\]]*\]\([^)]+\)\s*)+$');

  static List<MarkdownTextSection>? _tryParseStandaloneImage(String chunk) {
    if (!_onlyImagesPattern.hasMatch(chunk)) return null;
    final sections = <MarkdownTextSection>[];
    for (final match in _imagePattern.allMatches(chunk)) {
      sections.add(MarkdownTextSection._(
        type: MarkdownTextSectionType.standaloneImage,
        text: '',
        imageUrl: match.group(2),
        imageAlt: match.group(1),
      ));
    }
    return sections.isNotEmpty ? sections : null;
  }
}
