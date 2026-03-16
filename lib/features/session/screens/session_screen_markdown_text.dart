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

class _MarkdownTextBlock extends StatelessWidget {
  const _MarkdownTextBlock({
    required this.content,
    required this.isUser,
    required this.textColor,
  });

  final String content;
  final bool isUser;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final sections = _MarkdownTextSection.parse(content);
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
            color: textColor,
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading2:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        );
      case _MarkdownTextSectionType.heading3:
        return _buildRichText(
          section.text,
          baseStyle: TextStyle(
            color: textColor,
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
                          color: textColor,
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
                          color: textColor,
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
                        color: textColor,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRichText(
                        section.items[index],
                        baseStyle: TextStyle(
                          color: textColor,
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
            color: isUser
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.42)
                    : AppTheme.brandColor.withValues(alpha: 0.45),
                width: 3,
              ),
            ),
          ),
          child: _buildRichText(
            section.text,
            baseStyle: TextStyle(
              color: textColor.withValues(alpha: 0.92),
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
            color: textColor,
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
    return SelectableText.rich(
      TextSpan(
        children: _MarkdownInlineParser.buildSpans(
          raw,
          baseStyle: baseStyle,
          linkColor: isUser ? Colors.white : AppTheme.brandColor,
          inlineCodeColor: textColor,
          inlineCodeBackground: isUser
              ? Colors.white.withValues(alpha: 0.16)
              : AppTheme.neutral100,
        ),
      ),
    );
  }
}

