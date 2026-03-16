part of 'session_screen.dart';

class _MarkdownInlineParser {
  static final RegExp _pattern = RegExp(
    r'(\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*]+)\*|_([^_]+)_)',
  );

  static List<InlineSpan> buildSpans(
    String input, {
    required TextStyle baseStyle,
    required Color linkColor,
    required Color inlineCodeColor,
    required Color inlineCodeBackground,
  }) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _pattern.allMatches(input)) {
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: input.substring(cursor, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null && match.group(3) != null) {
        final label = match.group(2)!;
        final url = match.group(3)!;
        spans.add(
          TextSpan(
            text: label,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrlString(url);
              },
          ),
        );
      } else if (match.group(4) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: (baseStyle.fontSize ?? 14) - 1,
              backgroundColor: inlineCodeBackground,
              color: inlineCodeColor,
            ),
          ),
        );
      } else if (match.group(5) != null || match.group(6) != null) {
        spans.add(
          TextSpan(
            text: match.group(5) ?? match.group(6)!,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(7) != null || match.group(8) != null) {
        spans.add(
          TextSpan(
            text: match.group(7) ?? match.group(8)!,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < input.length) {
      spans.add(TextSpan(
        text: input.substring(cursor),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

