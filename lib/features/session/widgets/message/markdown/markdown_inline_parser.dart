import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../../core/theme/app_theme.dart';

enum InlineSegmentType {
  plain,
  link,
  inlineCode,
  bold,
  italic,
  filePath,
  image
}

class ParsedInlineSegment {
  const ParsedInlineSegment({
    required this.type,
    this.text,
    this.url,
    this.isBold = false,
    this.isItalic = false,
    this.isInlineCode = false,
    this.isLink = false,
    this.isFilePath = false,
    this.isImage = false,
  });
  final InlineSegmentType type;
  final String? text;
  final String? url;
  final bool isBold;
  final bool isItalic;
  final bool isInlineCode;
  final bool isLink;
  final bool isFilePath;
  final bool isImage;
}

class MarkdownInlineParser {
  static final RegExp _pattern = RegExp(
    r'(!\[([^\]]*)\]\(([^)]+)\)|\[([^\]]+)\]\(([^)]+)\)|`([^`]+)`|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*]+)\*|_([^_]+)_)',
  );
  static final RegExp _filePathPattern = RegExp(
    r'(?<![`\w/@\-])([\w][\w.\-]*(?:/[\w.\-]+)+\.[\w]+)(?![`\w/])',
  );
  static final Map<String, List<ParsedInlineSegment>> parseCache =
      <String, List<ParsedInlineSegment>>{};
  static const int _maxCacheSize = 200;

  static List<ParsedInlineSegment> _parse(String input) {
    final cached = parseCache[input];
    if (cached != null) return cached;
    final segments = <ParsedInlineSegment>[];
    var cursor = 0;

    for (final match in _pattern.allMatches(input)) {
      if (match.start > cursor)
        _parsePlain(input.substring(cursor, match.start), segments);
      if (match.group(2) != null && match.group(3) != null) {
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.image,
            text: match.group(2)!,
            url: match.group(3)!,
            isImage: true));
      } else if (match.group(4) != null && match.group(5) != null) {
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.link,
            text: match.group(4)!,
            url: match.group(5)!,
            isLink: true));
      } else if (match.group(6) != null) {
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.inlineCode,
            text: match.group(6)!,
            isInlineCode: true));
      } else if (match.group(7) != null || match.group(8) != null) {
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.bold,
            text: match.group(7) ?? match.group(8)!,
            isBold: true));
      } else if (match.group(9) != null || match.group(10) != null) {
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.italic,
            text: match.group(9) ?? match.group(10)!,
            isItalic: true));
      }
      cursor = match.end;
    }
    if (cursor < input.length) _parsePlain(input.substring(cursor), segments);
    if (segments.isEmpty)
      segments
          .add(ParsedInlineSegment(type: InlineSegmentType.plain, text: input));
    if (parseCache.length >= _maxCacheSize)
      parseCache.remove(parseCache.keys.first);
    parseCache[input] = segments;
    return segments;
  }

  static void _parsePlain(
      String plainText, List<ParsedInlineSegment> segments) {
    var localCursor = 0;
    for (final m in _filePathPattern.allMatches(plainText)) {
      if (m.start > localCursor)
        segments.add(ParsedInlineSegment(
            type: InlineSegmentType.plain,
            text: plainText.substring(localCursor, m.start)));
      segments.add(ParsedInlineSegment(
          type: InlineSegmentType.filePath,
          text: m.group(1)!,
          url: m.group(1)!,
          isFilePath: true));
      localCursor = m.end;
    }
    if (localCursor < plainText.length)
      segments.add(ParsedInlineSegment(
          type: InlineSegmentType.plain,
          text: plainText.substring(localCursor)));
  }

  static List<InlineSpan> buildSpans(
    String input, {
    required TextStyle baseStyle,
    required Color linkColor,
    required Color inlineCodeColor,
    required Color inlineCodeBackground,
    void Function(String filePath)? onFilePathTap,
    TapGestureRecognizer Function(void Function() onTap)? createRecognizer,
  }) {
    final segments = _parse(input);
    return [
      for (final seg in segments)
        _buildSpan(seg, baseStyle, linkColor, inlineCodeColor,
            inlineCodeBackground, onFilePathTap, createRecognizer)
    ];
  }

  static InlineSpan _buildSpan(
      ParsedInlineSegment seg,
      TextStyle baseStyle,
      Color linkColor,
      Color codeColor,
      Color codeBg,
      void Function(String)? onFilePathTap,
      TapGestureRecognizer Function(void Function())? createRecognizer) {
    switch (seg.type) {
      case InlineSegmentType.plain:
        return TextSpan(text: seg.text, style: baseStyle);
      case InlineSegmentType.link:
        return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
                color: linkColor, decoration: TextDecoration.underline),
            recognizer: createRecognizer != null
                ? createRecognizer(() => launchUrlString(seg.url!))
                : (TapGestureRecognizer()
                  ..onTap = () => launchUrlString(seg.url!)));
      case InlineSegmentType.inlineCode:
        return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
                fontFamily: AppTheme.fontFamilyMono,
                fontSize: (baseStyle.fontSize ?? 14) - 1,
                backgroundColor: codeBg,
                color: codeColor));
      case InlineSegmentType.bold:
        return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case InlineSegmentType.italic:
        return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic));
      case InlineSegmentType.filePath:
        return TextSpan(
            text: seg.text,
            style: baseStyle.copyWith(
                color: linkColor, decoration: TextDecoration.underline),
            recognizer: onFilePathTap != null
                ? (createRecognizer != null
                    ? createRecognizer(() => onFilePathTap(seg.url!))
                    : (TapGestureRecognizer()
                      ..onTap = () => onFilePathTap(seg.url!)))
                : null);
      case InlineSegmentType.image:
        return TextSpan(
            text: seg.text!.isEmpty ? 'Image' : seg.text,
            style: baseStyle.copyWith(
                color: linkColor, decoration: TextDecoration.underline),
            recognizer: createRecognizer != null
                ? createRecognizer(() => launchUrlString(seg.url!))
                : (TapGestureRecognizer()
                  ..onTap = () => launchUrlString(seg.url!)));
    }
  }
}
