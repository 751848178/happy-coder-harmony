import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

/// 功能设置页面
///
/// 对齐 Happy Coder 原项目的 `/settings/features`。
class FeaturesSettingsScreen extends ConsumerWidget {
  const FeaturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('功能设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: '实验功能',
            subtitle: '控制增强新建会话、会话同步和 Markdown 复制行为。',
            children: [
              SwitchListTile.adaptive(
                value: settings.experiments,
                onChanged: notifier.setExperiments,
                title: const Text('启用实验功能'),
                subtitle: const Text('允许展示和使用实验中能力。'),
              ),
              SwitchListTile.adaptive(
                value: settings.hideInactiveSessions,
                onChanged: notifier.setHideInactiveSessions,
                title: const Text('隐藏非活跃会话'),
                subtitle: const Text('在会话列表中默认只展示活跃会话。'),
              ),
              SwitchListTile.adaptive(
                value: settings.markdownCopyV2,
                onChanged: notifier.setMarkdownCopyV2,
                title: const Text('增强 Markdown 复制'),
                subtitle: const Text('长按消息时优先保留原始 Markdown。'),
              ),
              SwitchListTile.adaptive(
                value: settings.enableBackgroundSessionRefresh,
                onChanged: notifier.setEnableBackgroundSessionRefresh,
                title: const Text('后台持续更新消息'),
                subtitle: const Text(
                  '开启后会在应用进入后台后继续尽力刷新会话和消息；普通 HarmonyOS UIAbility 在锁屏后可能被系统回收，无法保证长期驻留，会增加电量和网络消耗。',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '交互偏好',
            subtitle: '对齐原项目的输入和命令面板偏好。',
            children: [
              SwitchListTile.adaptive(
                value: settings.commandPaletteEnabled,
                onChanged: notifier.setCommandPaletteEnabled,
                title: const Text('启用命令面板'),
                subtitle: const Text('允许通过命令面板快速跳转和执行操作。'),
              ),
              SwitchListTile.adaptive(
                value: settings.agentInputEnterToSend,
                onChanged: notifier.setAgentInputEnterToSend,
                title: const Text('回车直接发送'),
                subtitle: const Text('输入框回车时直接提交消息。'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                  height: 1.4,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
