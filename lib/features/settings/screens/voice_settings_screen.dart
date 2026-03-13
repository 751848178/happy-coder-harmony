import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/usage_models.dart';

/// 语音设置页面
class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);
    final currentLanguage = settings.voiceAssistantLanguage == null
        ? null
        : AppLanguages.getByCode(settings.voiceAssistantLanguage!);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('语音设置'),
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
            child: ListTile(
              leading: const Icon(Icons.language, color: AppTheme.brandColor),
              title: const Text('语音助手语言'),
              subtitle: Text(
                currentLanguage == null
                    ? '自动跟随系统语言'
                    : '${currentLanguage.nativeName} (${currentLanguage.name})',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.settingsVoiceLanguage),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.brandColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.brandColor.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              '该设置会影响语音会话中的默认语言提示，与原项目的 `/settings/voice` 行为保持一致。',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
