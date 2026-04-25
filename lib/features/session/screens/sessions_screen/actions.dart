part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  AppBar _buildSessionsAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('会话'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              _refreshSessionList();
            } else if (value == 'active') {
              _toggleShowActiveOnly();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, color: AppTheme.brandColor),
                  const SizedBox(width: 12),
                  Text(_isRefreshingSessions ? '正在刷新...' : '刷新会话列表'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'active',
              child: Row(
                children: [
                  Icon(
                    _showActiveOnly
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: AppTheme.brandColor,
                  ),
                  const SizedBox(width: 12),
                  const Text('仅显示活跃会话'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  FloatingActionButton _buildNewSessionFab() {
    return FloatingActionButton.extended(
      onPressed: _openNewSession,
      backgroundColor: AppTheme.brandColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: const Text('新建会话'),
    );
  }

  void _openNewSession() {
    final selectedMachineId = widget.selectedMachineId;
    if (selectedMachineId == null ||
        selectedMachineId == SessionsScreen.unknownMachineFilterId) {
      context.push(AppRoutes.newFlow);
      return;
    }
    context.push(
      Uri(
        path: AppRoutes.newFlow,
        queryParameters: {'machineId': selectedMachineId},
      ).toString(),
    );
  }

  Widget _buildEmptyState({
    required bool hasSessions,
    String? selectedMachineName,
  }) {
    if (hasSessions) {
      final hasMachineFilter =
          selectedMachineName != null && selectedMachineName.trim().isNotEmpty;
      final title = hasMachineFilter ? '该设备下没有匹配的会话' : '没有找到匹配的会话';
      final subtitle = hasMachineFilter ? '当前设备：$selectedMachineName' : null;
      return _SessionsEmptyState(
        icon: Icons.search_off,
        title: title,
        subtitle: subtitle,
      );
    }

    return const _SessionsEmptyState(
      icon: Icons.chat_bubble_outline,
      title: '还没有会话',
      subtitle: '点击下方按钮开始新的对话',
      emphasizeTitle: true,
    );
  }
}
