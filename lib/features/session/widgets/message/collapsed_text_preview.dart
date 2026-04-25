import 'package:flutter/material.dart';

import 'content_detection.dart';
import 'inline_code_panel.dart';
import 'session_message_bubble_presenter.dart';
import 'markdown/markdown_block.dart';
import 'markdown/markdown_table.dart';

class CollapsedTextPreview extends StatelessWidget {
  const CollapsedTextPreview({
    required this.content,
    required this.textColor,
    required this.isUser,
    required this.presenter,
  });
  final String content;
  final Color textColor;
  final bool isUser;
  final SessionMessageBubblePresenter presenter;

  @override
  Widget build(BuildContext context) {
    if (content.length <= 320 && !content.contains('```')) {
      return _plainPreview(presenter.plainTextPreview(content));
    }

    final blocks = MarkdownBlock.parse(content);
    final firstText = blocks.cast<MarkdownBlock?>().firstWhere(
        (b) =>
            b != null &&
            b.type == MarkdownBlockType.text &&
            b.text.trim().isNotEmpty,
        orElse: () => null);
    final firstCode = blocks.cast<MarkdownBlock?>().firstWhere(
        (b) =>
            b != null &&
            b.type == MarkdownBlockType.code &&
            b.text.trim().isNotEmpty,
        orElse: () => null);
    final firstTable = blocks.cast<MarkdownBlock?>().firstWhere(
        (b) =>
            b != null &&
            b.type == MarkdownBlockType.table &&
            b.headers.isNotEmpty,
        orElse: () => null);

    if (firstCode != null) {
      return _codePreview(firstText, firstCode);
    }
    if (firstTable != null) {
      return _tablePreview(firstTable);
    }
    if (looksLikeMarkdownContent(content)) {
      return _plainPreview(presenter.plainTextPreview(content), maxLines: 6);
    }
    return _plainPreview(presenter.plainTextPreview(content));
  }

  Widget _plainPreview(String text, {int maxLines = 4}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontSize: 14, height: 1.5)),
      const SizedBox(height: 8),
      Text(isUser ? '展开查看完整用户消息' : '展开查看完整消息',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72))),
    ]);
  }

  Widget _codePreview(MarkdownBlock? textBlock, MarkdownBlock codeBlock) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (textBlock != null) ...[
        Text(presenter.plainTextPreview(textBlock.text),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor, fontSize: 14, height: 1.5)),
        const SizedBox(height: 10),
      ],
      IgnorePointer(
          child: InlineCodePanel(
              code: codeBlock.text,
              language: codeBlock.language,
              isUser: isUser,
              collapsedLines: 4)),
      const SizedBox(height: 8),
      Text(isUser ? '展开查看完整用户消息' : '展开查看完整消息',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72))),
    ]);
  }

  Widget _tablePreview(MarkdownBlock tableBlock) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          height: 148,
          child: ClipRect(
              child: IgnorePointer(
                  child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: MarkdownTableBlock(
                          headers: tableBlock.headers,
                          rows: tableBlock.rows,
                          isUser: isUser,
                          textColor: textColor))))),
      const SizedBox(height: 8),
      Text(isUser ? '展开查看完整用户消息' : '展开查看完整消息',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72))),
    ]);
  }
}
