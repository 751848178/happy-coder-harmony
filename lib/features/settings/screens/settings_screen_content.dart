part of 'settings_screen.dart';

Widget _buildSettingsScaffold(_SettingsScreenState state) {
  state.ref.watch(sessionStateProvider);
  final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
  final settings = state.ref.watch(settingsStateProvider);
  final machines = state._collectMachines(
    sessionNotifier.machines,
    sessionNotifier.sessions,
  );
  final body = Stack(
    children: [
      ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.qr_code_scanner_outlined,
                color: const Color(0xFF007AFF),
                title: '扫描二维码连接终端',
                onTap: state._scanTerminalQrCode,
              ),
              _SettingsItem(
                icon: Icons.link_outlined,
                color: const Color(0xFF007AFF),
                title: '手动输入终端链接',
                onTap: state._showTerminalLinkDialog,
              ),
            ],
          ),
          _SettingsGroup(
            title: '已连接账户',
            children: [
              _SettingsItem(
                icon: Icons.smart_toy_outlined,
                color: const Color(0xFFD97757),
                title: 'Claude Code',
                subtitle: '通过终端完成 Claude 授权',
                onTap: () =>
                    state.context.push(AppRoutes.settingsConnectClaude),
              ),
            ],
          ),
          if (machines.isNotEmpty)
            _SettingsGroup(
              title: '机器',
              children: machines
                  .map(
                    (machine) => _SettingsItem(
                      icon: Icons.desktop_windows_outlined,
                      color: machine.isOnline
                          ? AppTheme.successColor
                          : AppTheme.neutral500,
                      title: machine.title,
                      subtitle: machine.subtitle,
                      onTap: () =>
                          state.context.push(AppRoutes.machine(machine.id)),
                    ),
                  )
                  .toList(),
            ),
          _buildSettingsFeaturesGroup(state, settings.experiments),
          _SettingsGroup(
            title: '关于',
            children: [
              _SettingsItem(
                icon: Icons.auto_awesome_outlined,
                color: const Color(0xFFFF9500),
                title: '更新日志',
                subtitle: '查看最近功能变更',
                onTap: () => state.context.push(AppRoutes.changelog),
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                color: AppTheme.neutral600,
                title: '关于',
                subtitle: '应用信息与相关链接',
                onTap: () => state.context.push(AppRoutes.settingsAbout),
              ),
            ],
          ),
        ],
      ),
      if (state._isConnectingTerminal) const _ConnectingOverlay(),
    ],
  );
  if (!state.widget.showAppBar) {
    return ColoredBox(color: AppTheme.neutral50, child: body);
  }
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      title: const Text('设置'),
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
    ),
    body: body,
  );
}

List<_MachineSummary> _collectSettingsMachines(
  List<Machine> machines,
  List<Session> sessions,
) {
  final items = <_MachineSummary>[];
  final seen = <String>{};
  for (final machine in machines) {
    if (!seen.add(machine.id)) {
      continue;
    }
    final host = machine.metadata?['host']?.toString() ?? machine.name;
    final platform =
        machine.platform ?? machine.metadata?['platform']?.toString();
    items.add(
      _MachineSummary(
        id: machine.id,
        title: machine.name,
        subtitle: [
          if (host != machine.name) host,
          if (platform != null && platform.isNotEmpty) platform,
          machine.active ? '在线' : '离线',
        ].join(' • '),
        isOnline: machine.active,
      ),
    );
  }
  final sortedSessions = [...sessions]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  for (final session in sortedSessions) {
    final machineId = session.metadata?['machineId']?.toString();
    if (machineId == null || machineId.isEmpty || !seen.add(machineId)) {
      continue;
    }
    final host = session.metadata?['host']?.toString() ?? machineId;
    final path = session.path ?? session.metadata?['path']?.toString();
    items.add(
      _MachineSummary(
        id: machineId,
        title: host,
        subtitle: [
          if (path != null && path.isNotEmpty) path,
          session.active ? '在线' : '离线',
        ].join(' • '),
        isOnline: session.active,
      ),
    );
  }
  return items;
}
