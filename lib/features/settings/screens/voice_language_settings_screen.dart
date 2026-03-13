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
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: BorderSide(color: AppTheme.neutral200),
            ),
            child: RadioListTile<String?>(
              value: null,
              groupValue: settings.voiceAssistantLanguage,
              onChanged: notifier.setVoiceAssistantLanguage,
              title: const Text('自动检测'),
              subtitle: const Text('跟随设备或当前会话上下文。'),
            ),
          ),
          const SizedBox(height: 12),
          ...AppLanguages.available.map((language) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: BorderSide(
                    color: settings.voiceAssistantLanguage == language.code
                        ? AppTheme.brandColor
                        : AppTheme.neutral200,
                  ),
                ),
                child: RadioListTile<String?>(
                  value: language.code,
                  groupValue: settings.voiceAssistantLanguage,
                  onChanged: notifier.setVoiceAssistantLanguage,
                  title: Text('${language.flag} ${language.nativeName}'),
                  subtitle: Text(language.name),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
