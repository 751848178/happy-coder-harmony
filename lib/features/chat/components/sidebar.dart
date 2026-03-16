import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import 'session_list.dart';

part 'sidebar_item.dart';
part 'sidebar_user_info.dart';

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
        border: Border(right: BorderSide(color: AppTheme.neutral300, width: 1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSidebarBrand(),
                const SizedBox(height: 16),
                const UserInfo(),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildSidebarSearch(),
          const SizedBox(height: 8),
          Expanded(child: SessionsList(onSessionTap: onSessionTap)),
          const Divider(height: 1),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarBrand() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.brandColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.code, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          AppConfig.appName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索会话...',
          hintStyle: TextStyle(color: AppTheme.neutral500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppTheme.neutral500, size: 20),
          filled: true,
          fillColor: AppTheme.neutral100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SidebarItem(
              icon: Icons.chat_bubble_outline, label: '所有会话', isActive: true),
          const SidebarItem(icon: Icons.favorite_border, label: '收藏会话'),
          const SidebarItem(icon: Icons.archive_outlined, label: '已归档'),
          const SizedBox(height: 8),
          const SidebarItem(icon: Icons.notifications_outlined, label: '通知'),
          SidebarItem(
              icon: Icons.settings_outlined, label: '设置', onTap: onSettingsTap),
        ],
      ),
    );
  }
}
