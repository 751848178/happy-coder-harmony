import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/server_config_service.dart';
import '../../../shared/platform/platform_storage.dart';

part 'notifier.dart';
part 'providers.dart';
part 'storage.dart';
part 'accessors.dart';
part 'state.dart';

/// 设置服务
///
/// 负责管理应用设置的持久化存储。
class SettingsService {
  SettingsService._();

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  static const String _keyDarkMode = 'dark_mode',
      _keyColorTheme = 'color_theme',
      _keyFontSize = 'font_size';
  static const String _keyEnableNotifications = 'enable_notifications',
      _keyEnableSound = 'enable_sound',
      _keyEnableVibration = 'enable_vibration';
  static const String _keyEnableMessageNotifications =
      'enable_message_notifications';
  static const String _keyEnableSystemNotifications =
      'enable_system_notifications';
  static const String _keyEnableErrorNotifications =
      'enable_error_notifications';
  static const String _keyDoNotDisturbStart = 'do_not_disturb_start',
      _keyDoNotDisturbEnd = 'do_not_disturb_end',
      _keyPermissionMode = 'permission_mode';
  static const String _keyUsername = 'username',
      _keyEmail = 'email',
      _keyExperiments = 'experiments';
  static const String _keyUseEnhancedSessionWizard =
      'use_enhanced_session_wizard';
  static const String _keyHideInactiveSessions = 'hide_inactive_sessions',
      _keyCommandPaletteEnabled = 'command_palette_enabled',
      _keyMarkdownCopyV2 = 'markdown_copy_v2';
  static const String _keyEnableBackgroundSessionRefresh =
      'enable_background_session_refresh';
  static const String _keyAgentInputEnterToSend = 'agent_input_enter_to_send';
  static const String _keyVoiceAssistantLanguage = 'voice_assistant_language';
  static const String _keyLastUsedAgent = 'last_used_agent';
  static const String _keyLastUsedPermissionMode = 'last_used_permission_mode';
  static const String _keyLastUsedModelMode = 'last_used_model_mode';

  static const String _storageKey = 'app_settings_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  Map<String, dynamic>? _cache;

  Future<void> clearAll() async {
    await init();
    final serverConfig = ServerConfigService.instance.snapshot;
    _cache = <String, dynamic>{};
    await _storage.delete(_storageKey);
    await ServerConfigService.instance.restoreSnapshot(serverConfig);
  }

  Future<void> resetToDefaults() async {
    await setDarkMode(false);
    await setColorTheme('brand');
    await setFontSize(1.0);
    await setEnableNotifications(true);
    await setEnableSound(true);
    await setEnableVibration(true);
    await setEnableMessageNotifications(true);
    await setEnableSystemNotifications(true);
    await setEnableErrorNotifications(true);
    await setDoNotDisturbStart(22);
    await setDoNotDisturbEnd(8);
    await setPermissionMode('manual');
    await setExperiments(false);
    await setUseEnhancedSessionWizard(false);
    await setHideInactiveSessions(false);
    await setCommandPaletteEnabled(true);
    await setMarkdownCopyV2(false);
    await setEnableBackgroundSessionRefresh(false);
    await setAgentInputEnterToSend(false);
    await setVoiceAssistantLanguage(null);
    await setLastUsedAgent(null);
    await setLastUsedPermissionMode(null);
    await setLastUsedModelMode(null);
  }
}
