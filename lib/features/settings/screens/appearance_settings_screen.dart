import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';

/// 外观设置屏幕
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);

    final List<ColorTheme> colorThemes = [
      const ColorTheme(
        id: 'brand',
        name: '品牌色',
        color: AppTheme.brandColor,
      ),
      const ColorTheme(
        id: 'blue',
        name: '蓝色',
        color: AppTheme.infoColor,
      ),
      const ColorTheme(
        id: 'green',
        name: '绿色',
        color: AppTheme.successColor,
      ),
      const ColorTheme(
        id: 'purple',
        name: '紫色',
        color: Color(0xFF9C27B0),
      ),
      const ColorTheme(
        id: 'orange',
        name: '橙色',
        color: AppTheme.warningColor,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('外观设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: AppTheme.spacingMd),
          // 主题模式
          _buildSectionHeader('主题模式'),
          _buildThemeModeSelector(
            isDarkMode: settings.isDarkMode,
            onTap: (value) => ref.read(settingsStateProvider.notifier).setDarkMode(value),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 颜色主题
          _buildSectionHeader('颜色主题'),
          _buildColorThemeSelector(
            colorThemes: colorThemes,
            selectedTheme: settings.colorTheme,
            onTap: (id) => ref.read(settingsStateProvider.notifier).setColorTheme(id),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 字体大小
          _buildSectionHeader('字体大小'),
          _buildFontSizeSlider(
            fontSize: settings.fontSize,
            onChanged: (value) => ref.read(settingsStateProvider.notifier).setFontSize(value),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // 其他
          _buildSectionHeader('其他'),
          _buildSettingItem(
            icon: Icons.animation_outlined,
            title: '动画效果',
            subtitle: '启用界面动画',
            onTap: () => _showComingSoonDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.border_outer,
            title: '圆角样式',
            subtitle: '调整界面圆角',
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

  Widget _buildThemeModeSelector({
    required bool isDarkMode,
    required ValueChanged<bool> onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeModeOption(
              icon: Icons.light_mode_outlined,
              title: '浅色',
              isSelected: !isDarkMode,
              onTap: () => onTap(false),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _ThemeModeOption(
              icon: Icons.dark_mode_outlined,
              title: '深色',
              isSelected: isDarkMode,
              onTap: () => onTap(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemeSelector({
    required List<ColorTheme> colorThemes,
    required String selectedTheme,
    required ValueChanged<String> onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        children: colorThemes.map((theme) {
          return _ColorThemeOption(
            theme: theme,
            isSelected: selectedTheme == theme.id,
            onTap: () => onTap(theme.id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeSlider({
    required double fontSize,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '字体大小',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(fontSize * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.brandColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Slider(
            value: fontSize,
            min: 0.75,
            max: 1.5,
            divisions: 6,
            activeColor: AppTheme.brandColor,
            onChanged: onChanged,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFontSizePreview(0.75, '小', fontSize),
              _buildFontSizePreview(1.0, '标准', fontSize),
              _buildFontSizePreview(1.25, '大', fontSize),
              _buildFontSizePreview(1.5, '特大', fontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizePreview(double scale, String label, double currentScale) {
    final displayScale = scale * (currentScale / 1.0);
    return Column(
      children: [
        Text(
          'Aa',
          style: TextStyle(fontSize: 14 * displayScale),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
        ),
      ],
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

/// 主题模式选项
class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
                size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 颜色主题
class ColorTheme {
  const ColorTheme({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

/// 颜色主题选项
class _ColorThemeOption extends StatelessWidget {
  const _ColorThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final ColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.color.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.color : AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
