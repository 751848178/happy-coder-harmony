part of 'socket_connection_screen.dart';

extension _SocketConnectionScreenActions on _SocketConnectionScreenState {
  void _subscribeToEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);
    socketNotifier.messageStream.listen((message) {
      if (!mounted) {
        return;
      }
      _appendMessage(message);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _connect() async {
    final credentials = ref.read(authStateProvider).credentials;
    if (credentials == null) {
      Logger.error('Not authenticated');
      return;
    }
    await ref.read(socketStateProvider.notifier).initialize(
          machineId: credentials.machineId,
          token: credentials.token,
        );
  }

  Future<void> _disconnect() async {
    await ref.read(socketStateProvider.notifier).disconnect();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final sessionId = _sessionIdController.text.trim();
    if (content.isEmpty || sessionId.isEmpty) {
      return;
    }

    await ref.read(socketStateProvider.notifier).sendMessage(
          sessionId: sessionId,
          content: content,
        );
    _messageController.clear();
  }
}
