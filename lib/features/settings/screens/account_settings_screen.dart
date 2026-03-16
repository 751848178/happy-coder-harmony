import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/settings_service.dart' as settings;
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/data/token_storage_service.dart';
import '../../../features/auth/presentation/scan_qr_screen.dart';
import '../../../features/encryption/domain/crypto_service.dart';
import '../../../features/session/data/session_repository.dart';
import '../../../shared/models/auth_models.dart';

part 'account_settings_screen_actions.dart';
part 'account_settings_screen_qr_dialog.dart';
part 'account_settings_screen_user_info.dart';

/// 账号设置屏幕
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final credentials = authState.credentials;

    if (credentials == null) {
      return _buildNotLoggedInView(context);
    }

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
          _UserInfoCard(credentials: credentials),
          const SizedBox(height: AppTheme.spacingLg),
          _buildSectionHeader('账号操作'),
          _buildSettingItem(
            icon: Icons.qr_code,
            title: '生成连接二维码',
            subtitle: '在另一台设备上扫描此二维码即可完成绑定',
            onTap: () => _showQRCodeDialog(context, ref),
          ),
          _buildSettingItem(
            icon: Icons.qr_code_scanner_outlined,
            title: '扫码连接设备',
            subtitle: '扫描另一台设备上的二维码，继续账户或电脑连接',
            onTap: () => _scanDeviceLink(context),
          ),
          _buildSettingItem(
            icon: Icons.computer,
            title: '连接电脑',
            subtitle: '扫码或粘贴 happy://terminal? 链接进行授权',
            onTap: () => context.push(AppRoutes.terminalConnect),
          ),
          _buildSettingItem(
            icon: Icons.dns_outlined,
            title: '服务器地址',
            subtitle: '确保与电脑端 Happy CLI 使用同一个后端地址',
            onTap: () => context.push(AppRoutes.settingsServer),
          ),
          _buildSettingItem(
            icon: Icons.vpn_key,
            title: '备份恢复密钥',
            subtitle: '保存当前设备的加密密钥，便于后续恢复',
            onTap: () => context.push(AppRoutes.backupKeys),
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

  Widget _buildNotLoggedInView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('账号设置'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              '未登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '请先登录以访问账号设置',
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }
}
