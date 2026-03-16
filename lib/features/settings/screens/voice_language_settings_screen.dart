import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/usage_models.dart';

/// 语音语言设置页
class VoiceLanguageSettingsScreen extends ConsumerWidget {
  const VoiceLanguageSettingsScreen({super.key});

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
        title: const Text('语音语言'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LanguageOptionCard(
            title: '自动检测',
            subtitle: '跟随设备或当前会话上下文。',
            selected: settings.voiceAssistantLanguage == null,
            onTap: () => notifier.setVoiceAssistantLanguage(null),
          ),
          const SizedBox(height: 12),
          ...AppLanguages.available.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LanguageOptionCard(
                title: '${language.flag} ${language.nativeName}',
                subtitle: language.name,
                selected: settings.voiceAssistantLanguage == language.code,
                onTap: () => notifier.setVoiceAssistantLanguage(language.code),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: selected ? AppTheme.brandColor : AppTheme.neutral200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppTheme.brandColor : AppTheme.neutral400,
        ),
      ),
    );
  }
}
