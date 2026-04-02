part of 'session_screen.dart';

enum _SessionMessageActionChoice {
  forward,
  saveTemplate,
  insertIntoComposer,
}

extension _SessionScreenMessageActions on _SessionScreenState {
  String _messageActionKindLabel(String kind) {
    switch (kind) {
      case 'text':
        return '文本消息';
      case 'tool-call':
        return '工具调用';
      case 'permission-request':
        return '权限请求';
      case 'turn-close':
        return '回合结束';
      case 'agent-event':
        return '状态事件';
      case 'error':
        return '错误消息';
      default:
        return kind;
    }
  }

  void _replaceComposerSelection({
    required int start,
    required int end,
    required String replacement,
  }) {
    _messageController.value = replaceComposerTextRange(
      currentValue: _messageController.value,
      start: start,
      end: end,
      replacement: replacement,
    );
    _messageFocusNode.requestFocus();
  }

  void _insertComposerTextAtCursor(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    _messageController.value = insertComposerTextAtSelection(
      currentValue: _messageController.value,
      insertion: text,
    );
    _messageFocusNode.requestFocus();
  }

  Future<void> _handleMessageActionChoice({
    required _SessionMessageActionChoice choice,
    required String actionText,
  }) async {
    switch (choice) {
      case _SessionMessageActionChoice.forward:
        await _forwardMessageToOtherSession(actionText);
        break;
      case _SessionMessageActionChoice.saveTemplate:
        await _showInputTemplateEditor(
          initialLabel: suggestSessionInputTemplateLabel(actionText),
          initialContent: actionText,
        );
        break;
      case _SessionMessageActionChoice.insertIntoComposer:
        _insertComposerTextAtCursor(actionText);
        break;
    }
  }

  Future<void> _showMessageActionSheet({
    required ReducerMessage message,
    required String actionText,
  }) async {
    final choice = await showBottomPopupSheet<_SessionMessageActionChoice>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '消息操作',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _messageActionKindLabel(message.kind),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.neutral200),
                  ),
                  child: Text(
                    actionText.trim(),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.forward_to_inbox_outlined),
                  title: const Text('转发到其他会话'),
                  subtitle: const Text('写入目标会话草稿，方便继续编辑后再发送。'),
                  onTap: () => Navigator.pop(
                    context,
                    _SessionMessageActionChoice.forward,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark_add_outlined),
                  title: const Text('保存到模板'),
                  subtitle: const Text('保存成快捷模板，之后可通过 `^` 快速插入。'),
                  onTap: () => Navigator.pop(
                    context,
                    _SessionMessageActionChoice.saveTemplate,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.input_rounded),
                  title: const Text('插入到输入框'),
                  subtitle: const Text('按当前光标或选区位置插入到本会话输入框。'),
                  onTap: () => Navigator.pop(
                    context,
                    _SessionMessageActionChoice.insertIntoComposer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) {
      return;
    }
    await _handleMessageActionChoice(choice: choice, actionText: actionText);
  }
}
