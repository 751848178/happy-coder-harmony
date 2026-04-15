part of 'session_screen.dart';

enum _MarkdownTextSectionType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  quote,
}

/// A widget that renders markdown-formatted text.
///
/// This is a [StatefulWidget] to cache the parsed sections —
/// [_MarkdownTextSection.parse] runs multiple regex splits per call,
/// so re-parsing on every build is wasteful when content hasn't changed.
class _MarkdownTextBlock extends StatefulWidget {
  const _MarkdownTextBlock({
    required this.content,
    required this.isUser,
    required this.textColor,
    this.onMessageAction,
    this.onFilePathTap,
  });

  final String content;
  final bool isUser;
  final Color textColor;
  final _SessionMessageActionHandler? onMessageAction;
  final void Function(String filePath)? onFilePathTap;

  @override
  State<_MarkdownTextBlock> createState() => _MarkdownTextBlockState();
}

class _MarkdownTextBlockState extends State<_MarkdownTextBlock> {
  List<_MarkdownTextSection> _sections = const [];
  // Gesture recognizers created for link/file-path taps in rich text.
  // Disposed in dispose() to prevent memory leaks — TextSpan.recognizer
  // is not auto-disposed by the framework.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _sections = _MarkdownTextSection.parse(widget.content);
  }

  @override
  void didUpdateWidget(covariant _MarkdownTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _sections = _MarkdownTextSection.parse(widget.content);
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          _buildSection(sections[index]),
          if (index != sections.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSection(_MarkdownTextSection section) {
    switch (section.type) {
      case _MarkdownTextSectionType.heading1:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: widget.textColor,
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading2:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: widget.textColor,
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading3:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: widget.textColor,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.bulletList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '•',
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRichText(
                        item,
                        baseStyle: TextStyle(
                          color: widget.textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _MarkdownTextSectionType.numberedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < section.items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRichText(
                        section.items[index],
                        baseStyle: TextStyle(
                          color: widget.textColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _MarkdownTextSectionType.quote:
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
                width: 3,
              ),
            ),
          ),
          child: _buildRichText(
            section.text,
            baseStyle: TextStyle(
              color: widget.textColor.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case _MarkdownTextSectionType.paragraph:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: widget.textColor,
            fontSize: 14,
            height: 1.5,
          ),
        );
    }
  }

  Widget _buildRichText(
    String raw, {
    required TextStyle baseStyle,
  }) {
    // Dispose previous recognizers before creating new ones on rebuild.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    TapGestureRecognizer createRecognizer(void Function() onTap) {
      final r = TapGestureRecognizer()..onTap = onTap;
      _recognizers.add(r);
      return r;
    }

    return SelectableText.rich(
      TextSpan(
        children: _MarkdownInlineParser.buildSpans(
          raw,
          baseStyle: baseStyle,
          linkColor: widget.isUser ? Colors.white : AppTheme.brandColor,
          inlineCodeColor: widget.textColor,
          inlineCodeBackground: widget.isUser
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.neutral100,
          onFilePathTap: widget.onFilePathTap,
          createRecognizer: createRecognizer,
        ),
      ),
      contextMenuBuilder: _buildMessageActionContextMenuBuilder(
        widget.onMessageAction,
      ),
    );
  }
}
