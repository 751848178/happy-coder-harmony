import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// App language
enum AppLanguage {
  zhCN, // 简体中文
  zhTW, // 繁体中文
  enUS, // English (US)
  jaJP, // Japanese
  koKR, // Korean
  frFR, // French
  deDE, // German
  esES, // Spanish
  ptBR, // Portuguese (Brazil)
  ruRU, // Russian
}

/// App locale
class AppLocale {
  final AppLanguage language;
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;

  const AppLocale({
    required this.language,
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });

  String get displayName => nativeName;
}

/// Built-in locales
class BuiltInLocales {
  static const all = [
    AppLocale(
      language: AppLanguage.zhCN,
      code: 'zh-CN',
      nativeName: '简体中文',
      englishName: 'Simplified Chinese',
      flag: '🇨🇳',
    ),
    AppLocale(
      language: AppLanguage.zhTW,
      code: 'zh-TW',
      nativeName: '繁體中文',
      englishName: 'Traditional Chinese',
      flag: '🇹🇼',
    ),
    AppLocale(
      language: AppLanguage.enUS,
      code: 'en-US',
      nativeName: 'English',
      englishName: 'English (US)',
      flag: '🇺🇸',
    ),
    AppLocale(
      language: AppLanguage.jaJP,
      code: 'ja-JP',
      nativeName: '日本語',
      englishName: 'Japanese',
      flag: '🇯🇵',
    ),
    AppLocale(
      language: AppLanguage.koKR,
      code: 'ko-KR',
      nativeName: '한국어',
      englishName: 'Korean',
      flag: '🇰🇷',
    ),
    AppLocale(
      language: AppLanguage.frFR,
      code: 'fr-FR',
      nativeName: 'Français',
      englishName: 'French',
      flag: '🇫🇷',
    ),
    AppLocale(
      language: AppLanguage.deDE,
      code: 'de-DE',
      nativeName: 'Deutsch',
      englishName: 'German',
      flag: '🇩🇪',
    ),
    AppLocale(
      language: AppLanguage.esES,
      code: 'es-ES',
      nativeName: 'Español',
      englishName: 'Spanish',
      flag: '🇪🇸',
    ),
    AppLocale(
      language: AppLanguage.ptBR,
      code: 'pt-BR',
      nativeName: 'Português',
      englishName: 'Portuguese (Brazil)',
      flag: '🇧🇷',
    ),
    AppLocale(
      language: AppLanguage.ruRU,
      code: 'ru-RU',
      nativeName: 'Русский',
      englishName: 'Russian',
      flag: '🇷🇺',
    ),
  ];

  static AppLocale? byLanguage(AppLanguage language) {
    for (final locale in all) {
      if (locale.language == language) return locale;
    }
    return null;
  }

  static AppLocale? byCode(String code) {
    for (final locale in all) {
      if (locale.code == code) return locale;
    }
    return null;
  }
}

/// Language Settings Widget
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
    _selectedLanguage = AppLanguage.zhCN; // Default
  }

  void _selectLanguage(AppLanguage language) {
    setState(() => _selectedLanguage = language);
    // In a real app, this would save to SharedPreferences and restart app
    _showLanguageChangedDialog(language);
  }

  void _showLanguageChangedDialog(AppLanguage language) {
    final locale = BuiltInLocales.byLanguage(language);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 48,
        ),
        title: const Text('语言已更改'),
        content: Text('应用将使用 ${locale?.nativeName ?? ''} 作为显示语言'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
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
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildLanguageList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
                    AppTheme.brandColor.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                color: Colors.white,
                size: 24,
              ),
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '更改语言将更新应用界面显示',
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

  Widget _buildLanguageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '可用语言',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...BuiltInLocales.all.map((locale) {
          final isSelected = locale.language == _selectedLanguage;
          return _LanguageTile(
            locale: locale,
            isSelected: isSelected,
            onTap: () => _selectLanguage(locale.language),
          );
        }).toList(),
      ],
    );
  }
}

/// Language list tile widget
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final AppLocale locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              locale.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.brandColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locale.englishName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.brandColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Quick language selector
class QuickLanguageSelector extends StatelessWidget {
  const QuickLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final AppLanguage? selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLocale = selectedLanguage != null
        ? BuiltInLocales.byLanguage(selectedLanguage!)
        : null;

    return DropdownButtonFormField<AppLocale>(
      value: selectedLocale,
      decoration: const InputDecoration(
        labelText: '语言',
        border: OutlineInputBorder(),
      ),
      items: BuiltInLocales.all.map((locale) {
        return DropdownMenuItem<AppLocale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(locale.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Text(locale.nativeName),
            ],
          ),
        );
      }).toList(),
      onChanged: (locale) {
        if (locale != null) {
          onLanguageChanged(locale.language);
        }
      },
    );
  }
}

/// Language model (for persistence)
class LanguageModel {
  final AppLanguage language;
  final DateTime? lastUpdated;

  const LanguageModel({
    required this.language,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      language: AppLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AppLanguage.zhCN,
      ),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  LanguageModel copyWith({
    AppLanguage? language,
    DateTime? lastUpdated,
  }) {
    return LanguageModel(
      language: language ?? this.language,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
