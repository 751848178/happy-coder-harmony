import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

part 'appearance_settings_screen_controls.dart';
part 'appearance_settings_screen_options.dart';
part 'appearance_settings_screen_support.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);
    final notifier = ref.read(settingsStateProvider.notifier);
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
          _buildAppearanceSectionHeader('主题模式'),
          _buildAppearanceThemeModeSelector(
            isDarkMode: settings.isDarkMode,
            onTap: notifier.setDarkMode,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAppearanceSectionHeader('颜色主题'),
          _buildAppearanceColorThemeSelector(
            colorThemes: _appearanceColorThemes,
            selectedTheme: settings.colorTheme,
            onTap: notifier.setColorTheme,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAppearanceSectionHeader('字体大小'),
          _buildAppearanceFontSizeSlider(
            fontSize: settings.fontSize,
            onChanged: notifier.setFontSize,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildAppearanceSectionHeader('其他'),
          _buildAppearanceSettingItem(
            icon: Icons.animation_outlined,
            title: '动画效果',
            subtitle: '启用界面动画',
            onTap: () => _showAppearanceComingSoonDialog(context),
          ),
          _buildAppearanceSettingItem(
            icon: Icons.border_outer,
            title: '圆角样式',
            subtitle: '调整界面圆角',
            onTap: () => _showAppearanceComingSoonDialog(context),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}
