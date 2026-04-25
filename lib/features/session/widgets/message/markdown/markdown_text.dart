import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_theme.dart';
import '../message_action_context_menu.dart';
import '../session_message_action_types.dart';
import 'markdown_inline_parser.dart';
import 'markdown_text_parser.dart';

class MarkdownTextBlock extends StatefulWidget {
  const MarkdownTextBlock({
    required this.content,
    required this.isUser,
    required this.textColor,
    this.onMessageAction,
    this.onFilePathTap,
  });
  final String content;
  final bool isUser;
  final Color textColor;
  final SessionMessageActionHandler? onMessageAction;
  final void Function(String filePath)? onFilePathTap;

  @override
  State<MarkdownTextBlock> createState() => _MarkdownTextBlockState();
}

class _MarkdownTextBlockState extends State<MarkdownTextBlock> {
  List<MarkdownTextSection> _sections = const [];
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _sections = MarkdownTextSection.parse(widget.content);
  }

  @override
  void didUpdateWidget(covariant MarkdownTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _sections = MarkdownTextSection.parse(widget.content);
    }
  }

  @override
  void dispose() {
    _resetRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _sections.length; i++) ...[
        _buildSection(_sections[i]),
        if (i != _sections.length - 1) const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _buildSection(MarkdownTextSection section) {
    switch (section.type) {
      case MarkdownTextSectionType.heading1:
        return _buildRichText(section.text,
            baseStyle: TextStyle(
                color: widget.textColor,
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w700));
      case MarkdownTextSectionType.heading2:
        return _buildRichText(section.text,
            baseStyle: TextStyle(
                color: widget.textColor,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w700));
      case MarkdownTextSectionType.heading3:
        return _buildRichText(section.text,
            baseStyle: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w700));
      case MarkdownTextSectionType.bulletList:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final item in section.items)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text('•',
                              style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 14,
                                  height: 1.45))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildRichText(item,
                              baseStyle: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 14,
                                  height: 1.5))),
                    ])),
        ]);
      case MarkdownTextSectionType.numberedList:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < section.items.length; i++)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}.',
                          style: TextStyle(
                              color: widget.textColor,
                              fontSize: 14,
                              height: 1.45)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildRichText(section.items[i],
                              baseStyle: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 14,
                                  height: 1.5))),
                    ])),
        ]);
      case MarkdownTextSectionType.quote:
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: widget.isUser
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border(
                left: BorderSide(
                    color: widget.isUser
                        ? Colors.white.withValues(alpha: 0.42)
                        : AppTheme.brandColor.withValues(alpha: 0.45),
                    width: 3)),
          ),
          child: _buildRichText(section.text,
              baseStyle: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.55,
                  fontStyle: FontStyle.italic)),
        );
      case MarkdownTextSectionType.paragraph:
        return _buildRichText(section.text,
            baseStyle:
                TextStyle(color: widget.textColor, fontSize: 14, height: 1.5));
      case MarkdownTextSectionType.standaloneImage:
        return _buildStandaloneImage(section.imageUrl, section.imageAlt);
    }
  }

  Widget _buildRichText(String raw, {required TextStyle baseStyle}) {
    TapGestureRecognizer createRecognizer(void Function() onTap) {
      final r = TapGestureRecognizer()..onTap = onTap;
      _recognizers.add(r);
      return r;
    }

    return SelectableText.rich(
      TextSpan(
          children: MarkdownInlineParser.buildSpans(
        raw,
        baseStyle: baseStyle,
        linkColor: widget.isUser ? Colors.white : AppTheme.brandColor,
        inlineCodeColor: widget.textColor,
        inlineCodeBackground: widget.isUser
            ? Colors.white.withValues(alpha: 0.16)
            : AppTheme.neutral100,
        onFilePathTap: widget.onFilePathTap,
        createRecognizer: createRecognizer,
      )),
      contextMenuBuilder: buildMessageActionContextMenu(widget.onMessageAction),
    );
  }

  void _resetRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Widget _buildStandaloneImage(String? url, String? alt) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => launchUrlString(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(
                height: 120,
                alignment: Alignment.center,
                child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(
              height: 80,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.neutral200)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.broken_image_outlined,
                    size: 20, color: AppTheme.neutral400),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(alt?.isNotEmpty == true ? alt! : url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppTheme.neutral500, fontSize: 13))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
