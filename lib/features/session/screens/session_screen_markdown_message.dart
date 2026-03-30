part of 'session_screen.dart';

class _MarkdownMessageContent extends StatefulWidget {
  const _MarkdownMessageContent({
    required this.content,
    required this.isUser,
    required this.textColor,
    this.onMessageAction,
  });

  final String content;
  final bool isUser;
  final Color textColor;
  final _SessionMessageActionHandler? onMessageAction;

  @override
  State<_MarkdownMessageContent> createState() =>
      _MarkdownMessageContentState();
}

class _MarkdownMessageContentState extends State<_MarkdownMessageContent> {
  late List<_MarkdownBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = _MarkdownBlock.parse(widget.content);
  }

  @override
  void didUpdateWidget(covariant _MarkdownMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _blocks = _MarkdownBlock.parse(widget.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _blocks.length; index++) ...[
          if (_blocks[index].type == _MarkdownBlockType.code)
            _InlineCodePanel(
              code: _blocks[index].text,
              language: _blocks[index].language,
              isUser: widget.isUser,
              onMessageAction: widget.onMessageAction,
            )
          else if (_blocks[index].type == _MarkdownBlockType.table)
            _MarkdownTableBlock(
              headers: _blocks[index].headers,
              rows: _blocks[index].rows,
              isUser: widget.isUser,
              textColor: widget.textColor,
              onMessageAction: widget.onMessageAction,
            )
          else
            _MarkdownTextBlock(
              content: _blocks[index].text,
              isUser: widget.isUser,
              textColor: widget.textColor,
              onMessageAction: widget.onMessageAction,
            ),
          if (index != _blocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
