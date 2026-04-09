part of 'session_screen.dart';

extension _SessionScreenStateActions on _SessionScreenState {
  bool _canAbortCurrentResponse(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) => _commandController.canAbortCurrentResponse(
        session,
        turnGroups,
        socketConnected: socketConnected,
      );

  Future<void> _handleAbortAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) => _commandController.handleAbortAction(
        session,
        turnGroups,
        socketConnected: socketConnected,
      );

  Future<void> _maybeAutoApprovePendingTools() =>
      _commandController.maybeAutoApprovePendingTools();

  void _showRenameDialog(Session? session) {
    if (session == null) {
      return;
    }
    final controller = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改会话名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的会话名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renameSession(controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(String alias) =>
      _commandController.renameSession(alias);

  Future<void> _handleSendAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (_isConversationBusy(session, turnGroups)) {
      _messageController.clear();
      _messageFocusNode.requestFocus();
      await _enqueueComposerMessage(text);
      return;
    }

    _messageController.clear();
    _messageFocusNode.requestFocus();
    await _dispatchMessage(text);
  }

  Future<bool> _dispatchMessage(
    String text, {
    bool restoreComposerOnError = true,
  }) => _commandController.dispatchMessage(
        text,
        restoreComposerOnError: restoreComposerOnError,
      );
}
