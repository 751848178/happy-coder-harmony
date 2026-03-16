part of 'socket_connection_screen.dart';

extension _SocketConnectionScreenMessages on _SocketConnectionScreenState {
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(SocketMessage message) {
    final isUser = message.type == SocketMessageType.user;
    final isSystem = message.type == SocketMessageType.system;
    final bubbleColor = isUser
        ? AppTheme.brandColor
        : isSystem
            ? Colors.grey.shade200
            : AppTheme.surface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: !isUser && !isSystem
              ? Border.all(color: AppTheme.neutral300)
              : null,
        ),
        child: _SocketMessageContent(message: message, isUser: isUser),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.neutral300)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            TextField(
              controller: _sessionIdController,
              decoration: InputDecoration(
                labelText: '会话 ID',
                hintText: '输入会话 ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocketMessageContent extends StatelessWidget {
  const _SocketMessageContent({
    required this.message,
    required this.isUser,
  });

  final SocketMessage message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final isSystem = message.type == SocketMessageType.system;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) _SocketMessageHeader(message: message),
        if (!isUser) const SizedBox(height: 4),
        Text(message.content, style: TextStyle(fontSize: 14, color: textColor)),
        if (message.metadata != null && message.metadata!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Metadata: ${message.metadata}',
              style: TextStyle(
                fontSize: 10,
                color: isSystem ? AppTheme.neutral600 : Colors.white70,
              ),
            ),
          ),
      ],
    );
  }
}

class _SocketMessageHeader extends StatelessWidget {
  const _SocketMessageHeader({required this.message});

  final SocketMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_messageIcon(message.type), size: 14, color: AppTheme.neutral600),
        const SizedBox(width: 4),
        Text(
          message.type.name,
          style: TextStyle(fontSize: 10, color: AppTheme.neutral600),
        ),
        const Spacer(),
        Text(
          message.timestamp?.toIso8601String().substring(11, 19) ?? '',
          style: TextStyle(fontSize: 10, color: AppTheme.neutral600),
        ),
      ],
    );
  }

  IconData _messageIcon(SocketMessageType type) {
    switch (type) {
      case SocketMessageType.server:
        return Icons.computer;
      case SocketMessageType.tool:
        return Icons.build;
      default:
        return Icons.info;
    }
  }
}
