part of 'terminal_list_screen.dart';

void _loadTerminalSessions(_TerminalListScreenState state) {
  state._updateView(() {
    state._sessions
      ..clear()
      ..addAll([
        TerminalSession(
          id: '1',
          name: '主终端',
          machine: 'localhost',
          path: '/home/user/project',
          status: TerminalStatus.active,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          lastActivity: DateTime.now(),
          pid: '12345',
        ),
        TerminalSession(
          id: '2',
          name: '开发环境',
          machine: 'dev-server',
          path: '/app',
          status: TerminalStatus.idle,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
          pid: '12346',
        ),
        TerminalSession(
          id: '3',
          name: '生产环境',
          machine: 'prod-server',
          path: '/var/www/app',
          status: TerminalStatus.disconnected,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          lastActivity: DateTime.now().subtract(const Duration(hours: 5)),
          exitCode: 0,
        ),
        TerminalSession(
          id: '4',
          name: '测试终端',
          machine: 'localhost',
          status: TerminalStatus.error,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
          exitCode: 1,
        ),
      ]);
  });
}

void _connectTerminalSession(
  _TerminalListScreenState state,
  TerminalSession session,
) {
  _updateSessionById(state, session.id, (_) {
    return session.copyWith(
      status: TerminalStatus.active,
      lastActivity: DateTime.now(),
    );
  });
  state._showSnackBar('已连接到 ${session.name}', isError: false);
}

void _disconnectTerminalSession(
  _TerminalListScreenState state,
  TerminalSession session,
) {
  _updateSessionById(state, session.id, (_) {
    return session.copyWith(
      status: TerminalStatus.disconnected,
      lastActivity: DateTime.now(),
      pid: null,
      exitCode: 0,
    );
  });
  state._showSnackBar('已断开 ${session.name}', isError: false);
}

void _deleteTerminalSession(_TerminalListScreenState state, String id) {
  state._updateView(() {
    state._sessions.removeWhere((session) => session.id == id);
  });
  state._showSnackBar('终端会话已删除', isError: false);
}

void _reconnectTerminalSession(
  _TerminalListScreenState state,
  TerminalSession session,
) {
  _updateSessionById(state, session.id, (_) {
    return session.copyWith(
      status: TerminalStatus.active,
      lastActivity: DateTime.now(),
      pid: '12345',
      exitCode: null,
    );
  });
  state._showSnackBar('已重新连接到 ${session.name}', isError: false);
}

void _updateSessionById(
  _TerminalListScreenState state,
  String sessionId,
  TerminalSession Function(TerminalSession current) update,
) {
  state._updateView(() {
    final index =
        state._sessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) {
      return;
    }
    state._sessions[index] = update(state._sessions[index]);
  });
}

String _formatTerminalTime(DateTime time) {
  return '${time.month}/${time.day} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
