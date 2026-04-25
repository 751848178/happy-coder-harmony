import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/usage_models.dart';

part 'widgets.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'zh';

  void _selectLanguage(String code) {
    setState(() => _selectedLanguage = code);
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
            _CurrentLanguageCard(
              currentLanguage: AppLanguages.getByCode(_selectedLanguage),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('可用语言'),
            const SizedBox(height: 12),
            ...AppLanguages.available.map(
              (language) => _LanguageTile(
                language: language,
                isSelected: _selectedLanguage == language.code,
                onTap: () => _selectLanguage(language.code),
              ),
            ),
            const SizedBox(height: 24),
            const _InfoCard(),
          ],
        ),
      ),
    );
  }
}
