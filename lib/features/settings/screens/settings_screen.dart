import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/scan_qr_screen.dart';

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
  bool _isConnectingTerminal = false;

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
    final machines =
        _collectMachines(sessionNotifier.machines, sessionNotifier.sessions);

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
                  onTap: _scanTerminalQrCode,
                ),
                _SettingsItem(
                  icon: Icons.link_outlined,
                  color: const Color(0xFF007AFF),
                  title: '手动输入终端链接',
                  onTap: _showTerminalLinkDialog,
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
        ),
        if (_isConnectingTerminal) const _ConnectingOverlay(),
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
      final platform =
          machine.platform ?? machine.metadata?['platform']?.toString();
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

  Future<void> _scanTerminalQrCode() async {
    if (_isConnectingTerminal) {
      return;
    }

    final scannedLink = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanQrScreen(
          title: '扫描电脑端二维码',
          description: '将摄像头对准电脑上显示的授权二维码，识别后会自动连接。',
        ),
      ),
    );
    if (!mounted || scannedLink == null || scannedLink.trim().isEmpty) {
      return;
    }

    await _connectTerminal(scannedLink.trim());
  }

  Future<void> _showTerminalLinkDialog() async {
    if (_isConnectingTerminal) {
      return;
    }

    final submittedLink = await showDialog<String>(
      context: context,
      builder: (_) => const _TerminalLinkInputDialog(),
    );

    if (!mounted || submittedLink == null || submittedLink.trim().isEmpty) {
      return;
    }

    await _connectTerminal(submittedLink.trim());
  }

  Future<void> _connectTerminal(String link) async {
    if (_isConnectingTerminal) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isConnectingTerminal = true;
    });

    try {
      await ref.read(authStateProvider.notifier).connectTerminal(link);
      await _prepareConnectedState();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('终端连接成功'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('终端连接失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingTerminal = false;
        });
      }
    }
  }

  Future<void> _prepareConnectedState() async {
    final authState = ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null) {
      return;
    }

    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final socketNotifier = ref.read(socketStateProvider.notifier);
    await Future.wait([
      sessionNotifier.loadSessions(force: true),
      sessionNotifier.loadMachines(force: true, allowFailure: true),
      socketNotifier.initialize(
        machineId: credentials.machineId,
        token: credentials.token,
      ),
    ]);
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

class _ConnectingOverlay extends StatelessWidget {
  const _ConnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.18),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.shadowMd,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  SizedBox(width: 14),
                  Text(
                    '正在连接终端...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLinkInputDialog extends StatefulWidget {
  const _TerminalLinkInputDialog();

  @override
  State<_TerminalLinkInputDialog> createState() =>
      _TerminalLinkInputDialogState();
}

class _TerminalLinkInputDialogState extends State<_TerminalLinkInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = '请输入终端链接';
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(trimmed);
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入终端链接'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_errorText == null) {
            return;
          }
          setState(() {
            _errorText = null;
          });
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'happy://terminal?BASE64URL_PUBLIC_KEY',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('连接'),
        ),
      ],
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
