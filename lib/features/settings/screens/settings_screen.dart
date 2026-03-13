import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

/// Upstream-aligned settings entry screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final settings = ref.watch(settingsStateProvider);
    final machines = _collectMachines(sessionNotifier.machines, sessionNotifier.sessions);

    final body = ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: Icons.qr_code_scanner_outlined,
              color: const Color(0xFF007AFF),
              title: '扫描二维码连接终端',
              onTap: () => context.push(AppRoutes.terminalList),
            ),
            _SettingsItem(
              icon: Icons.link_outlined,
              color: const Color(0xFF007AFF),
              title: '手动输入终端链接',
              onTap: () => context.push(AppRoutes.terminalConnect),
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
              onTap: () => context.push(AppRoutes.settingsConnectClaude),
            ),
          ],
        ),
        if (machines.isNotEmpty)
          _SettingsGroup(
            title: '机器',
            children: machines.map((machine) {
              return _SettingsItem(
                icon: Icons.desktop_windows_outlined,
                color: machine.isOnline
                    ? AppTheme.successColor
                    : AppTheme.neutral500,
                title: machine.title,
                subtitle: machine.subtitle,
                onTap: () => context.push(AppRoutes.machine(machine.id)),
              );
            }).toList(),
          ),
        _SettingsGroup(
          title: '功能',
          children: [
            _SettingsItem(
              icon: Icons.person_outline,
              color: const Color(0xFF007AFF),
              title: '账户',
              subtitle: '账户信息与偏好',
              onTap: () => context.push(AppRoutes.settingsAccount),
            ),
            _SettingsItem(
              icon: Icons.palette_outlined,
              color: const Color(0xFF5856D6),
              title: '外观',
              subtitle: '主题与显示偏好',
              onTap: () => context.push(AppRoutes.settingsAppearance),
            ),
            _SettingsItem(
              icon: Icons.mic_none_outlined,
              color: const Color(0xFF34C759),
              title: '语音助手',
              subtitle: '语音相关语言与偏好',
              onTap: () => context.push(AppRoutes.settingsVoice),
            ),
            _SettingsItem(
              icon: Icons.science_outlined,
              color: const Color(0xFFFF9500),
              title: '功能开关',
              subtitle: '实验能力与交互选项',
              onTap: () => context.push(AppRoutes.settingsFeatures),
            ),
            _SettingsItem(
              icon: Icons.tune_outlined,
              color: const Color(0xFFAF52DE),
              title: 'Profiles',
              subtitle: 'AI 后端与模型配置',
              onTap: () => context.push(AppRoutes.settingsProfiles),
            ),
            if (settings.experiments)
              _SettingsItem(
                icon: Icons.analytics_outlined,
                color: const Color(0xFF007AFF),
                title: '使用统计',
                subtitle: '查看 Token 与模型使用情况',
                onTap: () => context.push(AppRoutes.settingsUsage),
              ),
          ],
        ),
        _SettingsGroup(
          title: '关于',
          children: [
            _SettingsItem(
              icon: Icons.auto_awesome_outlined,
              color: const Color(0xFFFF9500),
              title: '更新日志',
              subtitle: '查看最近功能变更',
              onTap: () => context.push(AppRoutes.changelog),
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              color: AppTheme.neutral600,
              title: '关于',
              subtitle: '应用信息与相关链接',
              onTap: () => context.push(AppRoutes.settingsAbout),
            ),
          ],
        ),
      ],
    );

    if (!widget.showAppBar) {
      return ColoredBox(
        color: AppTheme.neutral50,
        child: body,
      );
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

  List<_MachineSummary> _collectMachines(
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
      final platform = machine.platform ?? machine.metadata?['platform']?.toString();
      final subtitleParts = <String>[
        if (host != machine.name) host,
        if (platform != null && platform.isNotEmpty) platform,
        machine.active ? '在线' : '离线',
      ];
      items.add(
        _MachineSummary(
          id: machine.id,
          title: machine.name,
          subtitle: subtitleParts.join(' • '),
          isOnline: machine.active,
        ),
      );
    }

    final sortedSessions = [...sessions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral600,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _MachineSummary {
  const _MachineSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isOnline,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool isOnline;
}
