part of 'session_screen.dart';

extension _SessionScreenMessageBubbleCollapsedText on _MessageBubbleState {
  Widget _buildCollapsedTextPreview({
    required String content,
    required Color textColor,
    required bool isUser,
  }) {
    final blocks = _MarkdownBlock.parse(content);
    final firstTextBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.text &&
              block.text.trim().isNotEmpty,
          orElse: () => null,
        );
    final firstCodeBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.code &&
              block.text.trim().isNotEmpty,
          orElse: () => null,
        );
    final firstTableBlock = blocks.cast<_MarkdownBlock?>().firstWhere(
          (block) =>
              block != null &&
              block.type == _MarkdownBlockType.table &&
              block.headers.isNotEmpty,
          orElse: () => null,
        );

    if (firstCodeBlock != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstTextBlock != null) ...[
            Text(
              _plainTextPreview(firstTextBlock.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          IgnorePointer(
            child: _InlineCodePanel(
              code: firstCodeBlock.text,
              language: firstCodeBlock.language,
              isUser: isUser,
              collapsedLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }

    if (firstTableBlock != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: ClipRect(
              child: IgnorePointer(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _MarkdownTableBlock(
                    headers: firstTableBlock.headers,
                    rows: firstTableBlock.rows,
                    isUser: isUser,
                    textColor: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }

    if (_looksLikeMarkdownContent(content)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: ClipRect(
              child: IgnorePointer(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: _MarkdownMessageContent(
                    content: content,
                    isUser: isUser,
                    textColor: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUser ? '展开查看完整用户消息' : '展开查看完整消息',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
            ),
          ),
        ],
      );
    }
    final preview = _plainTextPreview(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          preview,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isUser ? '展开查看完整用户消息' : '展开查看完整消息',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: isUser ? 0.82 : 0.72),
          ),
        ),
      ],
    );
  }

  bool _looksLikeMarkdownContent(String content) {
    return _looksLikeMarkdownContentValue(content);
  }
}
