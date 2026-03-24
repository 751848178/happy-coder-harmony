import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/settings_service.dart' as settings;
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/data/token_storage_service.dart';
import '../../../features/session/data/session_repository.dart';

part 'account_settings_screen_actions.dart';

/// 账号设置屏幕
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('账号设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('账户'),
          _buildSettingItem(
            icon: Icons.dns_outlined,
            title: '服务器地址',
            subtitle: '确保与电脑端 Happy CLI 使用同一个后端地址',
            onTap: () => context.push(AppRoutes.settingsServer),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSectionHeader('危险操作'),
          _buildSettingItem(
            icon: Icons.delete_outline,
            title: '清除本地数据',
            subtitle: '删除所有本地缓存和数据',
            iconColor: AppTheme.errorColor,
            onTap: () => _showClearDataDialog(context, ref),
          ),
          if (authState.credentials != null)
            _buildSettingItem(
              icon: Icons.logout,
              title: '退出登录',
              subtitle: '注销当前账号',
              iconColor: AppTheme.errorColor,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}
