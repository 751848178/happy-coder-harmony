part of 'terminal_list_screen.dart';

Widget _buildTerminalListScaffold(_TerminalListScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: _buildTerminalListAppBar(state),
    body: state._sessions.isEmpty
        ? _buildTerminalEmptyState()
        : _buildTerminalSessionList(state),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: state._addSession,
      backgroundColor: AppTheme.brandColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('新建会话'),
    ),
  );
}

PreferredSizeWidget _buildTerminalListAppBar(_TerminalListScreenState state) {
  return AppBar(
    backgroundColor: AppTheme.surface,
    foregroundColor: AppTheme.textPrimary,
    elevation: 0,
    title: const Text('终端会话'),
    actions: [
      if (state._sessions.isNotEmpty) _buildTerminalCountBadge(state),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          state._showSnackBar('正在刷新终端列表...', isError: false);
        },
        tooltip: '刷新',
      ),
    ],
  );
}

Widget _buildTerminalCountBadge(_TerminalListScreenState state) {
  return Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.brandColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state._activeCount > 0) ...[
          const Icon(Icons.lens, size: 8, color: AppTheme.successColor),
          const SizedBox(width: 4),
          Text(
            '${state._activeCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (state._errorCount > 0 && state._activeCount > 0)
          const SizedBox(width: 8),
        if (state._errorCount > 0) ...[
          const Icon(Icons.error, size: 12, color: AppTheme.errorColor),
          const SizedBox(width: 4),
          Text(
            '${state._errorCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildTerminalSessionList(_TerminalListScreenState state) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: state._sessions.length,
    itemBuilder: (context, index) {
      final session = state._sessions[index];
      return _TerminalSessionCard(
        session: session,
        onTap: () => state._connectToSession(session),
        onDisconnect: session.status == TerminalStatus.active
            ? () => state._disconnectSession(session)
            : session.status == TerminalStatus.disconnected
                ? () => state._reconnectSession(session)
                : null,
        onDetails: () => state._showSessionDetails(session),
        onDelete: () => state._showDeleteConfirmation(session),
      );
    },
  );
}

Widget _buildTerminalEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.terminal_outlined, size: 64, color: AppTheme.neutral400),
        const SizedBox(height: 16),
        const Text(
          '没有终端会话',
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 8),
        Text(
          '点击 + 按钮创建新的终端会话',
          style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
        ),
      ],
    ),
  );
}

Widget _buildTerminalStatusBadge(TerminalStatus status) {
  final (color, icon, label) = _terminalStatusPresentation(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

(Color, IconData, String) _terminalStatusPresentation(TerminalStatus status) {
  switch (status) {
    case TerminalStatus.active:
      return (AppTheme.successColor, Icons.lens, '活动');
    case TerminalStatus.idle:
      return (AppTheme.infoColor, Icons.circle_outlined, '空闲');
    case TerminalStatus.disconnected:
      return (AppTheme.neutral400, Icons.power_off, '已断开');
    case TerminalStatus.error:
      return (AppTheme.errorColor, Icons.error, '错误');
  }
}
