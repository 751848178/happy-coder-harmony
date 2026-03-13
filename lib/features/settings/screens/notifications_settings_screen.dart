import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';

/// 通知设置屏幕
class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);

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
          // 主开关
          _buildSectionHeader('通知'),
          _buildSwitchTile(
            icon: Icons.notifications_active,
            title: '启用通知',
            subtitle: '接收应用通知',
            value: settings.enableNotifications,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableNotifications(value),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 通知类型
          _buildSectionHeader('通知类型'),
          _buildSwitchTile(
            icon: Icons.message_outlined,
            title: '消息通知',
            subtitle: '新消息时通知',
            value: settings.enableMessageNotifications,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableMessageNotifications(value),
          ),
          _buildSwitchTile(
            icon: Icons.system_update_alt_outlined,
            title: '系统通知',
            subtitle: '系统更新和公告',
            value: settings.enableSystemNotifications,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableSystemNotifications(value),
          ),
          _buildSwitchTile(
            icon: Icons.error_outline,
            title: '错误通知',
            subtitle: '接收错误和警告通知',
            value: settings.enableErrorNotifications,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableErrorNotifications(value),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 通知方式
          _buildSectionHeader('通知方式'),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: '提示音',
            subtitle: '通知时播放声音',
            value: settings.enableSound,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableSound(value),
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: '震动',
            subtitle: '通知时震动',
            value: settings.enableVibration,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setEnableVibration(value),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 免打扰时段
          _buildSectionHeader('免打扰时段'),
          _buildDoNotDisturbTile(
            context: context,
            icon: Icons.bedtime_outlined,
            title: '免打扰时段',
            subtitle: '${settings.doNotDisturbStart}:00 - ${settings.doNotDisturbEnd}:00',
            startHour: settings.doNotDisturbStart,
            endHour: settings.doNotDisturbEnd,
            onTimeChanged: (start, end) {
              ref.read(settingsStateProvider.notifier).setDoNotDisturbPeriod(start, end);
            },
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.neutral600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.brandColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDoNotDisturbTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int startHour,
    required int endHour,
    required Function(int, int) onTimeChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.neutral600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
      onTap: () => _showDoNotDisturbDialog(context, startHour, endHour, onTimeChanged),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _showDoNotDisturbDialog(
    BuildContext context,
    int startHour,
    int endHour,
    Function(int, int) onTimeChanged,
  ) {
    int tempStart = startHour;
    int tempEnd = endHour;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置免打扰时段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('开始时间'),
            SizedBox(
              height: 120,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (value) => tempStart = value,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        '${index.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: index == startHour ? 20 : 16,
                          fontWeight: index == startHour ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('结束时间'),
            SizedBox(
              height: 120,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (value) => tempEnd = value,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        '${index.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: index == endHour ? 20 : 16,
                          fontWeight: index == endHour ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              onTimeChanged(tempStart, tempEnd);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
