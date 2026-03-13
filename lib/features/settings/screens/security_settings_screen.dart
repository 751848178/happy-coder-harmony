import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';

/// 安全设置屏幕
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final credentials = authState.credentials;

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
          // 加密状态
          _buildSectionHeader('加密状态'),
          _EncryptionStatusCard(credentials: credentials),
          const SizedBox(height: AppTheme.spacingLg),

          // 权限模式
          _buildSectionHeader('权限模式'),
          _buildSettingItem(
            icon: Icons.security,
            title: '默认权限模式',
            subtitle: '设置工具调用默认权限',
            onTap: () => _showPermissionModeDialog(context, ref),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 数据安全
          _buildSectionHeader('数据安全'),
          _buildSettingItem(
            icon: Icons.lock,
            title: '加密密钥管理',
            subtitle: '查看和管理您的加密密钥',
            onTap: () => context.push(AppRoutes.encryption),
          ),
          _buildSettingItem(
            icon: Icons.backup_outlined,
            title: '密钥备份',
            subtitle: '备份您的密钥到安全位置',
            onTap: () => context.push(AppRoutes.backupKeys),
          ),
          _buildSettingItem(
            icon: Icons.restore,
            title: '恢复密钥',
            subtitle: '从备份恢复您的密钥',
            onTap: () => _showRestoreDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 会话安全
          _buildSectionHeader('会话安全'),
          _buildSettingItem(
            icon: Icons.history,
            title: '会话历史保留',
            subtitle: '设置会话历史保留时间',
            onTap: () => _showComingSoonDialog(context),
          ),
          _buildSettingItem(
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
      child: ListTile(
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
        trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  void _showPermissionModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认权限模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PermissionModeOption(
              icon: Icons.block,
              title: '手动批准',
              description: '每次工具调用都需要手动确认',
              onTap: () {
                Navigator.pop(context);
                ref.read(settingsStateProvider.notifier).setPermissionMode('manual');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已设置为手动批准模式')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _PermissionModeOption(
              icon: Icons.check_circle,
              title: '自动批准',
              description: '自动批准所有工具调用',
              onTap: () {
                Navigator.pop(context);
                ref.read(settingsStateProvider.notifier).setPermissionMode('auto');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已设置为自动批准模式')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _PermissionModeOption(
              icon: Icons.help_outline,
              title: '询问模式',
              description: '根据工具类型询问是否批准',
              onTap: () {
                Navigator.pop(context);
                ref.read(settingsStateProvider.notifier).setPermissionMode('ask');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已设置为询问模式')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复密钥'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '备份ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
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
              Navigator.pop(context);
              // 暂时显示提示，实际恢复功能需要后端 API 支持
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('密钥恢复功能需要后端 API 支持')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('即将推出'),
        content: const Text('此功能正在开发中，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 权限模式选项
class _PermissionModeOption extends StatelessWidget {
  const _PermissionModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neutral200),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: AppTheme.brandColor),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 加密状态卡片
class _EncryptionStatusCard extends StatelessWidget {
  const _EncryptionStatusCard({required this.credentials});

  final dynamic credentials;

  @override
  Widget build(BuildContext context) {
    final isEncrypted = credentials != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEncrypted
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isEncrypted ? Icons.lock : Icons.lock_open,
                  color: isEncrypted ? AppTheme.successColor : AppTheme.neutral500,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEncrypted ? '已启用加密' : '未启用加密',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEncrypted
                          ? '您的数据使用端到端加密保护'
                          : '您的数据未加密，建议启用加密功能',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isEncrypted) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _EncryptionInfoRow(
              icon: Icons.vpn_key,
              label: '加密类型',
              value: 'Sodium (现代)',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _EncryptionInfoRow(
              icon: Icons.key,
              label: '公钥已设置',
              value: '是',
            ),
          ],
        ],
      ),
    );
  }
}

/// 加密信息行
class _EncryptionInfoRow extends StatelessWidget {
  const _EncryptionInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.neutral600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.neutral600,
            ),
          ),
        ),
      ],
    );
  }
}
