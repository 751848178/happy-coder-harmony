part of 'session_screen.dart';

/// Lightweight parsed representation of an inline markdown segment.
/// Avoids re-running regex on every build.
class _ParsedInlineSegment {
  const _ParsedInlineSegment({
    required this.type,
    this.text,
    this.url,
    this.isBold = false,
    this.isItalic = false,
    this.isInlineCode = false,
    this.isLink = false,
  });

  final _InlineSegmentType type;
  final String? text;
  final String? url;
  final bool isBold;
  final bool isItalic;
  final bool isInlineCode;
  final bool isLink;
}

enum _InlineSegmentType { plain, link, inlineCode, bold, italic }

class _MarkdownInlineParser {
  static final RegExp _pattern = RegExp(
    r'(\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*]+)\*|_([^_]+)_)',
  );

  /// Cache: input string → parsed segments.
  /// Keyed only on content because the regex parse is purely text-driven.
  static final Map<String, List<_ParsedInlineSegment>> _parseCache =
      <String, List<_ParsedInlineSegment>>{};
  static const int _maxCacheSize = 200;

  /// Parse inline markdown into lightweight data objects (cached).
  static List<_ParsedInlineSegment> _parse(String input) {
    final cached = _parseCache[input];
    if (cached != null) return cached;

    final segments = <_ParsedInlineSegment>[];
    var cursor = 0;

    for (final match in _pattern.allMatches(input)) {
      if (match.start > cursor) {
        segments.add(_ParsedInlineSegment(
          type: _InlineSegmentType.plain,
          text: input.substring(cursor, match.start),
        ));
      }

      if (match.group(2) != null && match.group(3) != null) {
        segments.add(_ParsedInlineSegment(
          type: _InlineSegmentType.link,
          text: match.group(2)!,
          url: match.group(3)!,
          isLink: true,
        ));
      } else if (match.group(4) != null) {
        segments.add(_ParsedInlineSegment(
          type: _InlineSegmentType.inlineCode,
          text: match.group(4)!,
          isInlineCode: true,
        ));
      } else if (match.group(5) != null || match.group(6) != null) {
        segments.add(_ParsedInlineSegment(
          type: _InlineSegmentType.bold,
          text: match.group(5) ?? match.group(6)!,
          isBold: true,
        ));
      } else if (match.group(7) != null || match.group(8) != null) {
        segments.add(_ParsedInlineSegment(
          type: _InlineSegmentType.italic,
          text: match.group(7) ?? match.group(8)!,
          isItalic: true,
        ));
      }

      cursor = match.end;
    }

    if (cursor < input.length) {
      segments.add(_ParsedInlineSegment(
        type: _InlineSegmentType.plain,
        text: input.substring(cursor),
      ));
    }

    if (segments.isEmpty) {
      segments.add(_ParsedInlineSegment(
        type: _InlineSegmentType.plain,
        text: input,
      ));
    }

    // LRU eviction
    if (_parseCache.length >= _maxCacheSize) {
      _parseCache.remove(_parseCache.keys.first);
    }
    _parseCache[input] = segments;
    return segments;
  }

  /// Build InlineSpan list from pre-parsed segments + styles.
  /// This is the public API — replaces the old monolithic buildSpans().
  static List<InlineSpan> buildSpans(
    String input, {
    required TextStyle baseStyle,
    required Color linkColor,
    required Color inlineCodeColor,
    required Color inlineCodeBackground,
  }) {
    final segments = _parse(input);
    return [
      for (final seg in segments)
        _buildSpanFromSegment(
          seg,
          baseStyle,
          linkColor,
          inlineCodeColor,
          inlineCodeBackground,
        ),
    ];
  }

  static InlineSpan _buildSpanFromSegment(
    _ParsedInlineSegment seg,
    TextStyle baseStyle,
    Color linkColor,
    Color inlineCodeColor,
    Color inlineCodeBackground,
  ) {
    switch (seg.type) {
      case _InlineSegmentType.plain:
        return TextSpan(text: seg.text, style: baseStyle);
      case _InlineSegmentType.link:
        return TextSpan(
          text: seg.text,
          style: baseStyle.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              launchUrlString(seg.url!);
            },
        );
      case _InlineSegmentType.inlineCode:
        return TextSpan(
          text: seg.text,
          style: baseStyle.copyWith(
            fontFamily: AppTheme.fontFamilyMono,
            fontSize: (baseStyle.fontSize ?? 14) - 1,
            backgroundColor: inlineCodeBackground,
            color: inlineCodeColor,
          ),
        );
      case _InlineSegmentType.bold:
        return TextSpan(
          text: seg.text,
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        );
      case _InlineSegmentType.italic:
        return TextSpan(
          text: seg.text,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        );
    }
  }
}
