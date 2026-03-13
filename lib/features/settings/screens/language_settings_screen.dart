import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/usage_models.dart';

/// Language Settings Screen
///
/// 语言设置页面
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'zh';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('语言设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Language
            _CurrentLanguageCard(
              currentLanguage: AppLanguages.getByCode(_selectedLanguage),
            ),
            const SizedBox(height: 24),

            // Available Languages
            const _SectionTitle('可用语言'),
            const SizedBox(height: 12),
            ...AppLanguages.available.map((lang) => _LanguageTile(
              language: lang,
              isSelected: _selectedLanguage == lang.code,
              onTap: () => _selectLanguage(lang.code),
            )),

            const SizedBox(height: 24),

            // App Language Info
            _InfoCard(),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(String code) {
    setState(() => _selectedLanguage = code);
    // TODO: Save preference and restart app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('语言已更改为 ${AppLanguages.getByCode(code)!.nativeName}'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() => _selectedLanguage = 'zh');
          },
        ),
      ),
    );
  }
}

/// Current Language Card
class _CurrentLanguageCard extends StatelessWidget {
  final LanguageSetting? currentLanguage;

  const _CurrentLanguageCard({required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandColor,
            AppTheme.brandColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(
                currentLanguage?.flag ?? '🌐',
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前语言',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLanguage?.nativeName ?? '未设置',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }
}

/// Language Tile
class _LanguageTile extends StatelessWidget {
  final LanguageSetting language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                language.flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info Card
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brandColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.brandColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '更改语言设置后，应用将重启以应用更改。部分内容可能需要重新加载。',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Title
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
