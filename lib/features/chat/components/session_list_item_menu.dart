part of 'session_list.dart';

class _SessionListMenuButton extends ConsumerWidget {
  const _SessionListMenuButton({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) => _handleMenuSelection(context, ref, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18),
            SizedBox(width: 12),
            Text('重命名'),
          ]),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(children: [
            Icon(Icons.archive_outlined, size: 18),
            SizedBox(width: 12),
            Text('归档'),
          ]),
        ),
        const PopupMenuItem(
          value: 3,
          child: Row(children: [
            Icon(Icons.push_pin_outlined, size: 18),
            SizedBox(width: 12),
            Text('置顶'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 4,
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: Colors.red),
            SizedBox(width: 12),
            Text('删除', style: TextStyle(color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, WidgetRef ref, int value) {
    final sessionService = ref.read(sessionStateProvider.notifier);
    switch (value) {
      case 1:
        _showRenameDialog(context, sessionService);
        break;
      case 2:
        _showArchiveDialog(context, sessionService);
        break;
      case 3:
        Logger.info('Pin session: ${session.id}');
        sessionService.updateDraft(session.id, session.draft ?? '');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已置顶')),
        );
        break;
      case 4:
        _showDeleteDialog(context, sessionService);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, SessionServiceNotifier service) {
    final controller = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != session.title) {
                service.updateDraft(session.id, newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('会话名称已更新')),
                );
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(
      BuildContext context, SessionServiceNotifier service) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档会话'),
        content: Text('确认归档"${session.title}"会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              service.updateDraft(session.id, null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('会话已归档')),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SessionServiceNotifier service) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认删除"${session.title}"会话吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.deleteSession(session.id);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('会话已删除')),
                );
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $error')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
