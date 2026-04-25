import 'package:flutter/material.dart';

import '../session_message_action_types.dart';
import 'markdown_block.dart';
import 'markdown_table.dart';
import 'markdown_text.dart';
import '../inline_code_panel.dart';

class MarkdownMessageContent extends StatefulWidget {
  const MarkdownMessageContent({
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
  State<MarkdownMessageContent> createState() => _MarkdownMessageContentState();
}

class _MarkdownMessageContentState extends State<MarkdownMessageContent> {
  late List<MarkdownBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = MarkdownBlock.parse(widget.content);
  }

  @override
  void didUpdateWidget(covariant MarkdownMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _blocks = MarkdownBlock.parse(widget.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _blocks.length; i++) ...[
        if (_blocks[i].type == MarkdownBlockType.code)
          InlineCodePanel(
              code: _blocks[i].text,
              language: _blocks[i].language,
              isUser: widget.isUser,
              onMessageAction: widget.onMessageAction)
        else if (_blocks[i].type == MarkdownBlockType.table)
          MarkdownTableBlock(
              headers: _blocks[i].headers,
              rows: _blocks[i].rows,
              isUser: widget.isUser,
              textColor: widget.textColor,
              onMessageAction: widget.onMessageAction)
        else
          MarkdownTextBlock(
              content: _blocks[i].text,
              isUser: widget.isUser,
              textColor: widget.textColor,
              onMessageAction: widget.onMessageAction,
              onFilePathTap: widget.onFilePathTap),
        if (i != _blocks.length - 1) const SizedBox(height: 10),
      ],
    ]);
  }
}
