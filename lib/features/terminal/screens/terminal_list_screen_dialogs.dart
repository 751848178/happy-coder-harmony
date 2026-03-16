part of 'terminal_list_screen.dart';

void _showAddSessionDialog(_TerminalListScreenState state) {
  state._nameController.clear();
  state._machineController.clear();
  state._pathController.clear();

  showDialog<void>(
    context: state.context,
    builder: (context) {
      return AlertDialog(
        title: const Text('新建终端会话'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: state._nameController,
                decoration: const InputDecoration(
                  labelText: '会话名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: state._machineController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  border: OutlineInputBorder(),
                  hintText: 'localhost',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: state._pathController,
                decoration: const InputDecoration(
                  labelText: '工作目录',
                  border: OutlineInputBorder(),
                  hintText: '/home/user',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _createTerminalSession(state, context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('创建'),
          ),
        ],
      );
    },
  );
}

void _createTerminalSession(
  _TerminalListScreenState state,
  BuildContext dialogContext,
) {
  if (state._nameController.text.trim().isEmpty) {
    state._showSnackBar('请输入会话名称', isError: true);
    return;
  }

  final session = TerminalSession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: state._nameController.text.trim(),
    machine: state._machineController.text.trim().isEmpty
        ? 'localhost'
        : state._machineController.text.trim(),
    path: state._pathController.text.trim().isEmpty
        ? null
        : state._pathController.text.trim(),
    status: TerminalStatus.idle,
    createdAt: DateTime.now(),
    lastActivity: DateTime.now(),
  );

  state._updateView(() {
    state._sessions.insert(0, session);
  });
  Navigator.pop(dialogContext);
  state._showSnackBar('终端会话已创建', isError: false);
}

void _showTerminalSessionDetails(
  _TerminalListScreenState state,
  TerminalSession session,
) {
  showDialog<void>(
    context: state.context,
    builder: (context) {
      return AlertDialog(
        title: Text(session.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('状态', _buildTerminalStatusBadge(session.status)),
              _DetailRow('主机', session.machine),
              _DetailRow('路径', session.path ?? '未设置'),
              _DetailRow('PID', session.pid ?? '-'),
              _DetailRow('创建时间', state._formatTime(session.createdAt)),
              _DetailRow('空闲时间', session._durationString),
              if (session.exitCode != null)
                _DetailRow('退出码', session.exitCode.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    },
  );
}

void _showDeleteTerminalConfirmation(
  _TerminalListScreenState state,
  TerminalSession session,
) {
  showDialog<void>(
    context: state.context,
    builder: (context) {
      return AlertDialog(
        title: const Text('删除终端会话'),
        content: Text('确认要删除 "${session.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state._deleteSession(session.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
}

void _showTerminalSnackBar(
  _TerminalListScreenState state,
  String message, {
  required bool isError,
}) {
  ScaffoldMessenger.of(state.context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ),
  );
}
