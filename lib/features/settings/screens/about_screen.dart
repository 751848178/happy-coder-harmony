import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

/// 关于屏幕
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          // Logo 和名称
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.brandColor,
                        AppTheme.brandDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.code,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  AppConfig.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutral600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.appDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppConfig.appVersion,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 信息列表
          _buildSectionHeader('应用信息'),
          _buildAboutInfoItem(
            icon: Icons.info_outline,
            title: '版本',
            value: AppConfig.appVersion,
          ),
          _buildAboutInfoItem(
            icon: Icons.build_outlined,
            title: '构建号',
            value: 'dev-2026-02-28',
          ),
          _buildAboutInfoItem(
            icon: Icons.calendar_today_outlined,
            title: '发布日期',
            value: '2026年2月',
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 链接
          _buildSectionHeader('相关链接'),
          _buildLinkItem(
            icon: Icons.language,
            title: '官方网站',
            subtitle: '访问官方网站了解更多',
            onTap: () => _openLink('https://github.com/slopus/happy'),
          ),
          _buildLinkItem(
            icon: Icons.description_outlined,
            title: '用户协议',
            subtitle: '查看用户协议和隐私政策',
            onTap: () => _showComingSoonDialog(context),
          ),
          _buildLinkItem(
            icon: Icons.bug_report_outlined,
            title: '反馈问题',
            subtitle: '报告 bug 或提出建议',
            onTap: () => _openLink('https://github.com/slopus/happy/issues'),
          ),
          _buildLinkItem(
            icon: Icons.star_outline,
            title: '给我们评分',
            subtitle: '在应用商店为我们评分',
            onTap: () => _showComingSoonDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 开源信息
          _buildSectionHeader('开源'),
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Text(
              '${AppConfig.appName} 是一个开源项目，遵循 MIT 协议开源。感谢所有贡献者的支持！',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: OutlinedButton.icon(
              onPressed: () => _openLink('https://github.com/slopus/happy'),
              icon: const Icon(Icons.code),
              label: const Text('查看源代码'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
                side: const BorderSide(color: AppTheme.brandColor),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // 版权信息
          Center(
            child: Text(
              '© 2026 ${AppConfig.appName}. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral400,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
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

  Widget _buildAboutInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: 4),
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
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.neutral600,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: AppTheme.infoColor, size: 22),
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

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
