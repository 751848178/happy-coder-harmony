part of '../session_detail.dart';

extension _SessionScreenStateActions on _SessionScreenState {
  bool _canAbortCurrentResponse(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) =>
      _commandController.canAbortCurrentResponse(
        session,
        turnGroups,
        socketConnected: socketConnected,
      );

  Future<void> _handleAbortAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) =>
      _commandController.handleAbortAction(
        session,
        turnGroups,
        socketConnected: socketConnected,
      );

  Future<void> _maybeAutoApprovePendingTools() =>
      _commandController.maybeAutoApprovePendingTools();

  Future<void> _showRenameDialog(Session? session) async {
    if (session == null) {
      return;
    }
    final controller = TextEditingController(text: session.title);
    try {
      final nextAlias = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );
      if (nextAlias == null) {
        return;
      }
      await _renameSession(nextAlias);
    } finally {
      controller.dispose();
    }
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
      await _enqueueComposerMessage(text);
      // Only clear the composer after successful enqueue to prevent data loss.
      if (_messageController.text.trim() == text) {
        _messageController.clear();
      }
      _messageFocusNode.requestFocus();
      return;
    }

    _messageController.clear();
    _messageFocusNode.requestFocus();
    await _dispatchMessage(text);
  }

  Future<bool> _dispatchMessage(
    String text, {
    bool restoreComposerOnError = true,
  }) =>
      _commandController.dispatchMessage(
        text,
        restoreComposerOnError: restoreComposerOnError,
      );
}
