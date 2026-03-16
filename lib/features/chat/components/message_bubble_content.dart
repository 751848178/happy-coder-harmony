part of 'message_bubble.dart';

extension _MessageBubbleContent on MessageBubble {
  Widget _buildMessageContent(BuildContext context, Color textColor) {
    if (message.isText && message.text != null) {
      return _buildMarkdownContent(context, message.text!, textColor);
    }
    if (message.isToolCall && message.tool != null) {
      return _buildToolCallContent(textColor);
    }
    if (message.isPermissionRequest && message.permission != null) {
      return _buildPermissionRequestContent(textColor);
    }
    if (message.isTurnClose) {
      return _buildTurnCloseContent();
    }
    return Text('Unknown message type', style: TextStyle(color: textColor));
  }

  Widget _buildMarkdownContent(
    BuildContext context,
    String content,
    Color textColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        h1: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        listBullet: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        blockquote: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.none,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        code: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 13,
          height: 1.4,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        a: TextStyle(
          color: AppTheme.brandColor,
          decoration: TextDecoration.underline,
        ),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
      ),
      onTapLink: (_, href, __) => Logger.info('Link tapped: $href'),
    );
  }
}
