part of 'session_info_screen.dart';

extension on _SessionInfoScreenState {
  Future<void> _loadSessionData() async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    await sessionNotifier.loadSessionMessages(widget.sessionId);
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.sessionDetail(widget.sessionId));
  }

  void _openCloneSession(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final uri = AppRoutes.newClonedSession(
      machineId: metadata['machineId']?.toString(),
      path: session.path ?? metadata['path']?.toString(),
      agent: metadata['flavor']?.toString(),
      permissionMode: metadata['currentOperatingModeCode']?.toString() ??
          session.permissionMode,
      modelMode: metadata['currentModelCode']?.toString() ?? session.modelMode,
    );
    context.push(uri);
  }

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
        title: const Text('会话信息'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  void _showEditSessionDialog(Session session) {
    final aliasController = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会话别名'),
        content: TextField(
          controller: aliasController,
          decoration: const InputDecoration(
            labelText: '别名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _renameSession(session, aliasController.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(Session session, String alias) async {
    try {
      await ref.read(sessionStateProvider.notifier).renameSession(
            sessionId: session.id,
            alias: alias,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会话别名已更新'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新别名失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _confirmDeleteSession(Session session) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确认要删除会话「${session.title}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(Session session) async {
    try {
      await ref.read(sessionStateProvider.notifier).deleteSession(session.id);
      if (!mounted) {
        return;
      }
      context.go('${AppRoutes.home}?tab=sessions');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除会话「${session.title}」'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _exportSession(Session session) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('会话导出功能待实现'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
}
