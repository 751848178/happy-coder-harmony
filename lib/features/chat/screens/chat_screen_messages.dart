part of 'chat_screen.dart';

extension _ChatScreenMessages on _ChatScreenState {
  void _handleSendMessage(String message) {
    final sessionId = widget.sessionId;
    if (sessionId == null) {
      return;
    }
    ref.read(sessionStateProvider.notifier).sendMessage(
          sessionId: sessionId,
          content: message,
        );
    _scrollToBottom();
  }

  void _handleSessionTap(String sessionId) {
    ref.read(currentSessionProvider.notifier).state =
        ref.read(sessionStateProvider).whenOrNull(
              ready: (sessions, _, __) => sessions[sessionId],
            );
  }

  void _handleMenuSelection(BuildContext context, int value) {
    switch (value) {
      case 1:
        Logger.info('Rename session');
        break;
      case 2:
        Logger.info('Pin session');
        break;
      case 3:
        Logger.info('Archive session');
        break;
      case 4:
        _showDeleteDialog(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: const Text('确认删除此会话吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Logger.info('Session deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = _currentMessages();
    if (messages.isEmpty) {
      return const _ChatEmptyMessages();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MessageBubble(
            message: message,
            isOwnMessage: index.isOdd,
          ),
        );
      },
    );
  }

  List<ReducerMessage> _currentMessages() {
    List<ReducerMessage> messages = const [];
    ref.watch(sessionStateProvider).whenOrNull(
      ready: (_, sessionMessages, __) {
        messages = sessionMessages[widget.sessionId]?.messages ?? const [];
      },
    );
    return messages;
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.neutral300)),
      ),
      child: MessageInput(
        sessionId: widget.sessionId!,
        hintText: '输入消息...',
        maxLines: 5,
        onSendMessage: _handleSendMessage,
      ),
    );
  }
}

class _ChatEmptyMessages extends StatelessWidget {
  const _ChatEmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send_outlined, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '发送第一条消息开始对话',
            style: TextStyle(color: AppTheme.neutral600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
