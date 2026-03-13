import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';

/// 个人资料屏幕
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final settings = ref.read(settingsStateProvider);
    _usernameController.text = settings.username;
    _emailController.text = settings.email;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final credentials = authState.credentials;
    final settings = ref.watch(settingsStateProvider);

    if (credentials == null) {
      return _buildNotLoggedInView(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('个人资料'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头像区域
            _buildAvatarSection(username: settings.username),
            const SizedBox(height: AppTheme.spacingLg),

            // 用户信息
            _buildSectionHeader('基本信息'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: '用户名',
                    value: settings.username,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: '邮箱',
                    value: settings.email,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    icon: Icons.fingerprint,
                    label: 'Machine ID',
                    value: _getMachineId(credentials),
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '注册时间',
                    value: '2026年1月',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // 使用统计
            _buildSectionHeader('使用统计'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Icons.chat_bubble_outline,
                    label: '总消息数',
                    value: '0',
                  ),
                  _buildDivider(),
                  _buildStatRow(
                    icon: Icons.list_alt,
                    label: '会话数',
                    value: '0',
                  ),
                  _buildDivider(),
                  _buildStatRow(
                    icon: Icons.access_time,
                    label: '使用时长',
                    value: '0 小时',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // 快捷操作
            _buildSectionHeader('快捷操作'),
            _buildQuickAction(
              icon: Icons.settings_outlined,
              title: '账号设置',
              onTap: () => context.push(AppRoutes.settingsAccount),
            ),
            _buildQuickAction(
              icon: Icons.backup_outlined,
              title: '密钥管理',
              onTap: () => context.push(AppRoutes.encryption),
            ),
            _buildQuickAction(
              icon: Icons.history,
              title: '会话历史',
              onTap: () => context.push(AppRoutes.sessions),
            ),
            _buildQuickAction(
              icon: Icons.share_outlined,
              title: '分享应用',
              onTap: () => _shareApp(),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
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
        title: const Text('个人资料'),
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
              '请先登录以访问个人资料',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
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

  Widget _buildAvatarSection({required String username}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandColor,
            AppTheme.brandDark,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '在线',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI 驱动的代码开发助手',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.neutral600),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.brandColor),
          const SizedBox(width: AppTheme.spacingMd),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Divider(height: 1),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
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
        trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  String _getMachineId(dynamic credentials) {
    try {
      if (credentials is Map) {
        return credentials['machineId']?.toString().substring(0, 12) ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  void _showEditDialog(BuildContext context) {
    final settings = ref.read(settingsStateProvider);
    _usernameController.text = settings.username;
    _emailController.text = settings.email;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑资料'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
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
              _saveProfile();
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

  void _saveProfile() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isNotEmpty) {
      ref.read(settingsStateProvider.notifier).setUsername(username);
    }
    if (email.isNotEmpty) {
      ref.read(settingsStateProvider.notifier).setEmail(email);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('资料已保存'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Happy Coder - AI 驱动的代码开发助手\n\n'
        'https://github.com/slopus/happy',
        subject: 'Happy Coder',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
