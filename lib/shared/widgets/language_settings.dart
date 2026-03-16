import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'language_settings_data.dart';
part 'language_settings_widgets.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<LanguageSettingsScreen> {
  AppLanguage? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = AppLanguage.zhCN;
  }

  void _selectLanguage(AppLanguage language) {
    setState(() => _selectedLanguage = language);
    _showLanguageChangedDialog(language);
  }

  void _showLanguageChangedDialog(AppLanguage language) {
    final locale = BuiltInLocales.byLanguage(language);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle,
              color: AppTheme.successColor, size: 48),
          title: const Text('语言已更改'),
          content: Text('应用将使用 ${locale?.nativeName ?? ''} 作为显示语言'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('语言设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLanguageInfoCard(),
          const SizedBox(height: 24),
          _buildLanguageList(this),
        ],
      ),
    );
  }
}

Widget _buildLanguageInfoCard() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandColor,
                  AppTheme.brandColor.withValues(alpha: 0.7)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择您的首选语言',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  '更改语言将更新应用界面显示',
                  style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLanguageList(_LanguageSettingsState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '可用语言',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary),
      ),
      const SizedBox(height: 12),
      ...BuiltInLocales.all.map((locale) {
        final isSelected = locale.language == state._selectedLanguage;
        return _LanguageTile(
          locale: locale,
          isSelected: isSelected,
          onTap: () => state._selectLanguage(locale.language),
        );
      }),
    ],
  );
}
