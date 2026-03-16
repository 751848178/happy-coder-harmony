import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

part 'notifications_settings_screen_support.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

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
        title: const Text('通知设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          _buildNotificationsSectionHeader('通知'),
          _buildNotificationSwitchTile(
            icon: Icons.notifications_active,
            title: '启用通知',
            subtitle: '接收应用通知',
            value: settings.enableNotifications,
            onChanged: notifier.setEnableNotifications,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildNotificationsSectionHeader('通知类型'),
          _buildNotificationSwitchTile(
            icon: Icons.message_outlined,
            title: '消息通知',
            subtitle: '新消息时通知',
            value: settings.enableMessageNotifications,
            onChanged: notifier.setEnableMessageNotifications,
          ),
          _buildNotificationSwitchTile(
            icon: Icons.system_update_alt_outlined,
            title: '系统通知',
            subtitle: '系统更新和公告',
            value: settings.enableSystemNotifications,
            onChanged: notifier.setEnableSystemNotifications,
          ),
          _buildNotificationSwitchTile(
            icon: Icons.error_outline,
            title: '错误通知',
            subtitle: '接收错误和警告通知',
            value: settings.enableErrorNotifications,
            onChanged: notifier.setEnableErrorNotifications,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildNotificationsSectionHeader('通知方式'),
          _buildNotificationSwitchTile(
            icon: Icons.volume_up,
            title: '提示音',
            subtitle: '通知时播放声音',
            value: settings.enableSound,
            onChanged: notifier.setEnableSound,
          ),
          _buildNotificationSwitchTile(
            icon: Icons.vibration,
            title: '震动',
            subtitle: '通知时震动',
            value: settings.enableVibration,
            onChanged: notifier.setEnableVibration,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildNotificationsSectionHeader('免打扰时段'),
          _buildDoNotDisturbTile(
            context: context,
            icon: Icons.bedtime_outlined,
            title: '免打扰时段',
            subtitle:
                '${settings.doNotDisturbStart}:00 - ${settings.doNotDisturbEnd}:00',
            startHour: settings.doNotDisturbStart,
            endHour: settings.doNotDisturbEnd,
            onTimeChanged: notifier.setDoNotDisturbPeriod,
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}
