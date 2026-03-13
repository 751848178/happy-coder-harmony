import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import 'session_list.dart';

/// 侧边栏导航项
class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badge,
    this.showNotificationDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final int? badge;
  final bool showNotificationDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.brandColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? AppTheme.brandColor
                      : AppTheme.neutral600,
                ),
                // 通知红点
                if (showNotificationDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.brandColor
                    : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // 徽章
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 用户信息组件
class UserInfo extends ConsumerWidget {
  const UserInfo({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.isAuthenticated ? ref.watch(currentUserProvider) : null;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 头像
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.brandColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user!.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 用户名和邮箱
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email ?? '',
                    style: TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 更多按钮
            IconButton(
              icon: const Icon(Icons.more_vert),
              iconSize: 18,
              color: AppTheme.neutral600,
              onPressed: () => _showUserMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              label: '个人资料',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              label: '设置',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildMenuItem(
              icon: Icons.logout,
              label: '退出登录',
              onTap: () {
                Navigator.pop(context);
                // 执行退出登录
                ref.read(authStateProvider.notifier).logout();
                // 导航到登录页面
                context.push(AppRoutes.auth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neutral600),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }
}

/// 侧边栏组件
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    this.onSessionTap,
    this.onSettingsTap,
  });

  final void Function(String sessionId)? onSessionTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(
            color: AppTheme.neutral300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo 和用户信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Happy Coder',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 用户信息
                UserInfo(onTap: () {}),
              ],
            ),
          ),

          const Divider(height: 1),

          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索会话...',
                hintStyle: TextStyle(
                  color: AppTheme.neutral500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.neutral500,
                  size: 20,
                ),
                filled: true,
                fillColor: AppTheme.neutral100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 会话列表
          Expanded(
            child: SessionsList(
              onSessionTap: onSessionTap,
            ),
          ),

          const Divider(height: 1),

          // 底部导航
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SidebarItem(
                  icon: Icons.chat_bubble_outline,
                  label: '所有会话',
                  isActive: true,
                  onTap: () {},
                ),
                SidebarItem(
                  icon: Icons.favorite_border,
                  label: '收藏会话',
                  onTap: () {},
                ),
                SidebarItem(
                  icon: Icons.archive_outlined,
                  label: '已归档',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                SidebarItem(
                  icon: Icons.notifications_outlined,
                  label: '通知',
                  onTap: () {},
                ),
                SidebarItem(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
