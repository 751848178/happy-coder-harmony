part of 'session_screen.dart';

extension _SessionScreenMessageBubbleContent on _MessageBubbleState {
  Widget _buildTextMessage(BuildContext context) {
    final text = message.text;
    if (text == null || text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final isUser = sessionMessageIsUserAuthored(message);
    final isThinking = message.metadata?['outputType'] == 'thinking';
    final isOptimistic = message.metadata?['optimistic'] == true;
    final canCollapse = _shouldCollapseTextMessage(text);
    final bubbleColor = isUser ? AppTheme.brandColor : AppTheme.surface;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppTheme.radiusLg),
              topRight: const Radius.circular(AppTheme.radiusLg),
              bottomLeft: Radius.circular(isUser ? AppTheme.radiusLg : 4),
              bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusLg),
            ),
            border: Border.all(
              color: isUser ? AppTheme.brandColor : AppTheme.neutral200,
            ),
            boxShadow: isUser ? null : AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canCollapse)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildCollapseButton(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppTheme.brandColor,
                    collapsedLabel: '展开',
                    expandedLabel: '收起',
                  ),
                ),
              if (canCollapse) const SizedBox(height: 6),
              Opacity(
                opacity: isThinking ? 0.84 : 1,
                child: _collapsed && canCollapse
                    ? _buildCollapsedTextPreview(
                        content: text,
                        textColor: textColor,
                        isUser: isUser,
                      )
                    : _MarkdownMessageContent(
                        content: text,
                        isUser: isUser,
                        textColor: textColor,
                        onMessageAction: onMessageAction,
                      ),
              ),
              if (isUser && isOptimistic) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '发送中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
