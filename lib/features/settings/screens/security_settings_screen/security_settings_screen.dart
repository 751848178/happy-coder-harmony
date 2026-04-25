import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

part 'dialogs.dart';
part 'encryption_widgets.dart';
part 'widgets.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(authStateProvider).credentials;
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('安全设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          _buildSecuritySectionHeader('加密状态'),
          _EncryptionStatusCard(credentials: credentials),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSecuritySectionHeader('权限模式'),
          _buildSecuritySettingItem(
            icon: Icons.security,
            title: '默认权限模式',
            subtitle: '设置工具调用默认权限',
            onTap: () => _showPermissionModeDialog(context, ref),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSecuritySectionHeader('数据安全'),
          _buildSecuritySettingItem(
            icon: Icons.lock,
            title: '加密密钥管理',
            subtitle: '查看和管理您的加密密钥',
            onTap: () => context.push(AppRoutes.encryption),
          ),
          _buildSecuritySettingItem(
            icon: Icons.backup_outlined,
            title: '密钥备份',
            subtitle: '备份您的密钥到安全位置',
            onTap: () => context.push(AppRoutes.backupKeys),
          ),
          _buildSecuritySettingItem(
            icon: Icons.restore,
            title: '恢复密钥',
            subtitle: '从备份恢复您的密钥',
            onTap: () => _showRestoreDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSecuritySectionHeader('会话安全'),
          _buildSecuritySettingItem(
            icon: Icons.history,
            title: '会话历史保留',
            subtitle: '设置会话历史保留时间',
            onTap: () => _showComingSoonDialog(context),
          ),
          _buildSecuritySettingItem(
            icon: Icons.delete_sweep,
            title: '自动清理',
            subtitle: '自动清理过期的会话数据',
            onTap: () => _showComingSoonDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}
