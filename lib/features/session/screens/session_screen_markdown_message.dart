part of 'session_screen.dart';

class _MarkdownMessageContent extends StatelessWidget {
  const _MarkdownMessageContent({
    required this.content,
    required this.isUser,
    required this.textColor,
  });

  final String content;
  final bool isUser;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final blocks = _MarkdownBlock.parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          if (blocks[index].type == _MarkdownBlockType.code)
            _InlineCodePanel(
              code: blocks[index].text,
              language: blocks[index].language,
              isUser: isUser,
            )
          else if (blocks[index].type == _MarkdownBlockType.table)
            _MarkdownTableBlock(
              headers: blocks[index].headers,
              rows: blocks[index].rows,
              isUser: isUser,
              textColor: textColor,
            )
          else
            _MarkdownTextBlock(
              content: blocks[index].text,
              isUser: isUser,
              textColor: textColor,
            ),
          if (index != blocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

