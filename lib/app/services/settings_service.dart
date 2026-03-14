import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/config/server_config_service.dart';
import '../../shared/platform/platform_storage.dart';

part 'settings_notifier.dart';
part 'settings_providers.dart';
part 'settings_service_accessors.dart';
part 'settings_state.dart';

/// 设置服务
///
/// 负责管理应用设置的持久化存储。
class SettingsService {
  SettingsService._();

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  static const String _keyDarkMode = 'dark_mode';
  static const String _keyColorTheme = 'color_theme';
  static const String _keyFontSize = 'font_size';
  static const String _keyEnableNotifications = 'enable_notifications';
  static const String _keyEnableSound = 'enable_sound';
  static const String _keyEnableVibration = 'enable_vibration';
  static const String _keyEnableMessageNotifications =
      'enable_message_notifications';
  static const String _keyEnableSystemNotifications =
      'enable_system_notifications';
  static const String _keyEnableErrorNotifications =
      'enable_error_notifications';
  static const String _keyDoNotDisturbStart = 'do_not_disturb_start';
  static const String _keyDoNotDisturbEnd = 'do_not_disturb_end';
  static const String _keyPermissionMode = 'permission_mode';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyExperiments = 'experiments';
  static const String _keyUseEnhancedSessionWizard =
      'use_enhanced_session_wizard';
  static const String _keyHideInactiveSessions = 'hide_inactive_sessions';
  static const String _keyCommandPaletteEnabled = 'command_palette_enabled';
  static const String _keyMarkdownCopyV2 = 'markdown_copy_v2';
  static const String _keyAgentInputEnterToSend = 'agent_input_enter_to_send';
  static const String _keyVoiceAssistantLanguage = 'voice_assistant_language';
  static const String _keyLastUsedAgent = 'last_used_agent';
  static const String _keyLastUsedProfile = 'last_used_profile';
  static const String _keyLastUsedPermissionMode = 'last_used_permission_mode';
  static const String _keyLastUsedModelMode = 'last_used_model_mode';

  static const String _storageKey = 'app_settings_v1';

  final PlatformStorage _storage = PlatformStorage.instance;
  Map<String, dynamic>? _cache;

  Future<void> init() async {
    if (_cache != null) {
      return;
    }
    final raw = await _storage.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cache = <String, dynamic>{};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cache = decoded;
      } else if (decoded is Map) {
        _cache = decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        _cache = <String, dynamic>{};
      }
    } catch (_) {
      _cache = <String, dynamic>{};
    }
  }

  Map<String, dynamic> get _values => _cache ?? const <String, dynamic>{};

  bool _getBool(String key, bool fallback) {
    final value = _values[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    return fallback;
  }

  String _getString(String key, String fallback) {
    final value = _values[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String? _getNullableString(String key) {
    final value = _values[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int _getInt(String key, int fallback) {
    final value = _values[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  double _getDouble(String key, double fallback) {
    final value = _values[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  Future<void> _persist() async {
    await init();
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(_cache ?? const <String, dynamic>{}),
    );
  }

  Future<void> _setBool(String key, bool value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setString(String key, String value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setNullableString(String key, String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      _cache!.remove(key);
    } else {
      _cache![key] = value;
    }
    await _persist();
  }

  Future<void> _setInt(String key, int value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> _setDouble(String key, double value) async {
    await init();
    _cache![key] = value;
    await _persist();
  }

  Future<void> clearAll() async {
    await init();
    final customServerUrl = ServerConfigService.instance.customServerUrl;
    _cache = <String, dynamic>{};
    await _storage.delete(_storageKey);
    await ServerConfigService.instance.restoreCustomServerUrl(customServerUrl);
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
    await setAgentInputEnterToSend(false);
    await setVoiceAssistantLanguage(null);
    await setLastUsedAgent(null);
    await setLastUsedProfile(null);
    await setLastUsedPermissionMode(null);
    await setLastUsedModelMode(null);
  }
}
