import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

part 'about_screen_actions.dart';
part 'about_screen_widgets.dart';

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
          _buildAboutHero(),
          const SizedBox(height: AppTheme.spacingXl),
          _buildAboutSectionHeader('应用信息'),
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
          _buildAboutSectionHeader('相关链接'),
          _buildAboutLinkItem(
            icon: Icons.language,
            title: '官方网站',
            subtitle: '访问官方网站了解更多',
            onTap: () => _openAboutLink('https://github.com/slopus/happy'),
          ),
          _buildAboutLinkItem(
            icon: Icons.description_outlined,
            title: '用户协议',
            subtitle: '查看用户协议和隐私政策',
            onTap: () => _showAboutComingSoonDialog(context),
          ),
          _buildAboutLinkItem(
            icon: Icons.bug_report_outlined,
            title: '反馈问题',
            subtitle: '报告 bug 或提出建议',
            onTap: () =>
                _openAboutLink('https://github.com/slopus/happy/issues'),
          ),
          _buildAboutLinkItem(
            icon: Icons.star_outline,
            title: '给我们评分',
            subtitle: '在应用商店为我们评分',
            onTap: () => _showAboutComingSoonDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAboutOpenSourceSection(),
          const SizedBox(height: AppTheme.spacingXl),
          Center(
            child: Text(
              '© 2026 ${AppConfig.appName}. All rights reserved.',
              style: const TextStyle(fontSize: 12, color: AppTheme.neutral400),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}
