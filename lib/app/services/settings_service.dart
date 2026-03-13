import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/server_config_service.dart';
import '../../shared/platform/platform_storage.dart';

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

  bool get isDarkMode => _getBool(_keyDarkMode, false);
  Future<void> setDarkMode(bool value) => _setBool(_keyDarkMode, value);

  String get colorTheme => _getString(_keyColorTheme, 'brand');
  Future<void> setColorTheme(String value) => _setString(_keyColorTheme, value);

  double get fontSize => _getDouble(_keyFontSize, 1.0);
  Future<void> setFontSize(double value) => _setDouble(_keyFontSize, value);

  bool get enableNotifications => _getBool(_keyEnableNotifications, true);
  Future<void> setEnableNotifications(bool value) =>
      _setBool(_keyEnableNotifications, value);

  bool get enableSound => _getBool(_keyEnableSound, true);
  Future<void> setEnableSound(bool value) => _setBool(_keyEnableSound, value);

  bool get enableVibration => _getBool(_keyEnableVibration, true);
  Future<void> setEnableVibration(bool value) =>
      _setBool(_keyEnableVibration, value);

  bool get enableMessageNotifications =>
      _getBool(_keyEnableMessageNotifications, true);
  Future<void> setEnableMessageNotifications(bool value) =>
      _setBool(_keyEnableMessageNotifications, value);

  bool get enableSystemNotifications =>
      _getBool(_keyEnableSystemNotifications, true);
  Future<void> setEnableSystemNotifications(bool value) =>
      _setBool(_keyEnableSystemNotifications, value);

  bool get enableErrorNotifications =>
      _getBool(_keyEnableErrorNotifications, true);
  Future<void> setEnableErrorNotifications(bool value) =>
      _setBool(_keyEnableErrorNotifications, value);

  int get doNotDisturbStart => _getInt(_keyDoNotDisturbStart, 22);
  Future<void> setDoNotDisturbStart(int value) =>
      _setInt(_keyDoNotDisturbStart, value);

  int get doNotDisturbEnd => _getInt(_keyDoNotDisturbEnd, 8);
  Future<void> setDoNotDisturbEnd(int value) =>
      _setInt(_keyDoNotDisturbEnd, value);

  String get permissionMode => _getString(_keyPermissionMode, 'manual');
  Future<void> setPermissionMode(String value) =>
      _setString(_keyPermissionMode, value);

  String get username => _getString(_keyUsername, 'Happy Coder');
  Future<void> setUsername(String value) => _setString(_keyUsername, value);

  String get email => _getString(_keyEmail, 'user@example.com');
  Future<void> setEmail(String value) => _setString(_keyEmail, value);

  bool get experiments => _getBool(_keyExperiments, false);
  Future<void> setExperiments(bool value) => _setBool(_keyExperiments, value);

  bool get useEnhancedSessionWizard =>
      _getBool(_keyUseEnhancedSessionWizard, false);
  Future<void> setUseEnhancedSessionWizard(bool value) =>
      _setBool(_keyUseEnhancedSessionWizard, value);

  bool get hideInactiveSessions => _getBool(_keyHideInactiveSessions, false);
  Future<void> setHideInactiveSessions(bool value) =>
      _setBool(_keyHideInactiveSessions, value);

  bool get commandPaletteEnabled => _getBool(_keyCommandPaletteEnabled, true);
  Future<void> setCommandPaletteEnabled(bool value) =>
      _setBool(_keyCommandPaletteEnabled, value);

  bool get markdownCopyV2 => _getBool(_keyMarkdownCopyV2, false);
  Future<void> setMarkdownCopyV2(bool value) =>
      _setBool(_keyMarkdownCopyV2, value);

  bool get agentInputEnterToSend => _getBool(_keyAgentInputEnterToSend, false);
  Future<void> setAgentInputEnterToSend(bool value) =>
      _setBool(_keyAgentInputEnterToSend, value);

  String? get voiceAssistantLanguage =>
      _getNullableString(_keyVoiceAssistantLanguage);
  Future<void> setVoiceAssistantLanguage(String? value) =>
      _setNullableString(_keyVoiceAssistantLanguage, value);

  String? get lastUsedAgent => _getNullableString(_keyLastUsedAgent);
  Future<void> setLastUsedAgent(String? value) =>
      _setNullableString(_keyLastUsedAgent, value);

  String? get lastUsedProfile => _getNullableString(_keyLastUsedProfile);
  Future<void> setLastUsedProfile(String? value) =>
      _setNullableString(_keyLastUsedProfile, value);

  String? get lastUsedPermissionMode =>
      _getNullableString(_keyLastUsedPermissionMode);
  Future<void> setLastUsedPermissionMode(String? value) =>
      _setNullableString(_keyLastUsedPermissionMode, value);

  String? get lastUsedModelMode => _getNullableString(_keyLastUsedModelMode);
  Future<void> setLastUsedModelMode(String? value) =>
      _setNullableString(_keyLastUsedModelMode, value);

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

/// 设置状态
class SettingsState {
  const SettingsState({
    this.isDarkMode = false,
    this.colorTheme = 'brand',
    this.fontSize = 1.0,
    this.enableNotifications = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableMessageNotifications = true,
    this.enableSystemNotifications = true,
    this.enableErrorNotifications = true,
    this.doNotDisturbStart = 22,
    this.doNotDisturbEnd = 8,
    this.permissionMode = 'manual',
    this.username = 'Happy Coder',
    this.email = 'user@example.com',
    this.experiments = false,
    this.useEnhancedSessionWizard = false,
    this.hideInactiveSessions = false,
    this.commandPaletteEnabled = true,
    this.markdownCopyV2 = false,
    this.agentInputEnterToSend = false,
    this.voiceAssistantLanguage,
    this.lastUsedAgent,
    this.lastUsedProfile,
    this.lastUsedPermissionMode,
    this.lastUsedModelMode,
  });

  final bool isDarkMode;
  final String colorTheme;
  final double fontSize;
  final bool enableNotifications;
  final bool enableSound;
  final bool enableVibration;
  final bool enableMessageNotifications;
  final bool enableSystemNotifications;
  final bool enableErrorNotifications;
  final int doNotDisturbStart;
  final int doNotDisturbEnd;
  final String permissionMode;
  final String username;
  final String email;
  final bool experiments;
  final bool useEnhancedSessionWizard;
  final bool hideInactiveSessions;
  final bool commandPaletteEnabled;
  final bool markdownCopyV2;
  final bool agentInputEnterToSend;
  final String? voiceAssistantLanguage;
  final String? lastUsedAgent;
  final String? lastUsedProfile;
  final String? lastUsedPermissionMode;
  final String? lastUsedModelMode;

  SettingsState copyWith({
    bool? isDarkMode,
    String? colorTheme,
    double? fontSize,
    bool? enableNotifications,
    bool? enableSound,
    bool? enableVibration,
    bool? enableMessageNotifications,
    bool? enableSystemNotifications,
    bool? enableErrorNotifications,
    int? doNotDisturbStart,
    int? doNotDisturbEnd,
    String? permissionMode,
    String? username,
    String? email,
    bool? experiments,
    bool? useEnhancedSessionWizard,
    bool? hideInactiveSessions,
    bool? commandPaletteEnabled,
    bool? markdownCopyV2,
    bool? agentInputEnterToSend,
    Object? voiceAssistantLanguage = _sentinel,
    Object? lastUsedAgent = _sentinel,
    Object? lastUsedProfile = _sentinel,
    Object? lastUsedPermissionMode = _sentinel,
    Object? lastUsedModelMode = _sentinel,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      colorTheme: colorTheme ?? this.colorTheme,
      fontSize: fontSize ?? this.fontSize,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableMessageNotifications:
          enableMessageNotifications ?? this.enableMessageNotifications,
      enableSystemNotifications:
          enableSystemNotifications ?? this.enableSystemNotifications,
      enableErrorNotifications:
          enableErrorNotifications ?? this.enableErrorNotifications,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      permissionMode: permissionMode ?? this.permissionMode,
      username: username ?? this.username,
      email: email ?? this.email,
      experiments: experiments ?? this.experiments,
      useEnhancedSessionWizard:
          useEnhancedSessionWizard ?? this.useEnhancedSessionWizard,
      hideInactiveSessions: hideInactiveSessions ?? this.hideInactiveSessions,
      commandPaletteEnabled:
          commandPaletteEnabled ?? this.commandPaletteEnabled,
      markdownCopyV2: markdownCopyV2 ?? this.markdownCopyV2,
      agentInputEnterToSend:
          agentInputEnterToSend ?? this.agentInputEnterToSend,
      voiceAssistantLanguage: voiceAssistantLanguage == _sentinel
          ? this.voiceAssistantLanguage
          : voiceAssistantLanguage as String?,
      lastUsedAgent: lastUsedAgent == _sentinel
          ? this.lastUsedAgent
          : lastUsedAgent as String?,
      lastUsedProfile: lastUsedProfile == _sentinel
          ? this.lastUsedProfile
          : lastUsedProfile as String?,
      lastUsedPermissionMode: lastUsedPermissionMode == _sentinel
          ? this.lastUsedPermissionMode
          : lastUsedPermissionMode as String?,
      lastUsedModelMode: lastUsedModelMode == _sentinel
          ? this.lastUsedModelMode
          : lastUsedModelMode as String?,
    );
  }
}

const Object _sentinel = Object();

/// 设置状态管理器
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._service) : super(const SettingsState()) {
    _loadSettings();
  }

  final SettingsService _service;

  Future<void> _loadSettings() async {
    await _service.init();
    state = SettingsState(
      isDarkMode: _service.isDarkMode,
      colorTheme: _service.colorTheme,
      fontSize: _service.fontSize,
      enableNotifications: _service.enableNotifications,
      enableSound: _service.enableSound,
      enableVibration: _service.enableVibration,
      enableMessageNotifications: _service.enableMessageNotifications,
      enableSystemNotifications: _service.enableSystemNotifications,
      enableErrorNotifications: _service.enableErrorNotifications,
      doNotDisturbStart: _service.doNotDisturbStart,
      doNotDisturbEnd: _service.doNotDisturbEnd,
      permissionMode: _service.permissionMode,
      username: _service.username,
      email: _service.email,
      experiments: _service.experiments,
      useEnhancedSessionWizard: _service.useEnhancedSessionWizard,
      hideInactiveSessions: _service.hideInactiveSessions,
      commandPaletteEnabled: _service.commandPaletteEnabled,
      markdownCopyV2: _service.markdownCopyV2,
      agentInputEnterToSend: _service.agentInputEnterToSend,
      voiceAssistantLanguage: _service.voiceAssistantLanguage,
      lastUsedAgent: _service.lastUsedAgent,
      lastUsedProfile: _service.lastUsedProfile,
      lastUsedPermissionMode: _service.lastUsedPermissionMode,
      lastUsedModelMode: _service.lastUsedModelMode,
    );
  }

  void setDarkMode(bool value) {
    _service.setDarkMode(value);
    state = state.copyWith(isDarkMode: value);
  }

  void setColorTheme(String value) {
    _service.setColorTheme(value);
    state = state.copyWith(colorTheme: value);
  }

  void setFontSize(double value) {
    _service.setFontSize(value);
    state = state.copyWith(fontSize: value);
  }

  void setEnableNotifications(bool value) {
    _service.setEnableNotifications(value);
    state = state.copyWith(enableNotifications: value);
  }

  void setEnableSound(bool value) {
    _service.setEnableSound(value);
    state = state.copyWith(enableSound: value);
  }

  void setEnableVibration(bool value) {
    _service.setEnableVibration(value);
    state = state.copyWith(enableVibration: value);
  }

  void setEnableMessageNotifications(bool value) {
    _service.setEnableMessageNotifications(value);
    state = state.copyWith(enableMessageNotifications: value);
  }

  void setEnableSystemNotifications(bool value) {
    _service.setEnableSystemNotifications(value);
    state = state.copyWith(enableSystemNotifications: value);
  }

  void setEnableErrorNotifications(bool value) {
    _service.setEnableErrorNotifications(value);
    state = state.copyWith(enableErrorNotifications: value);
  }

  void setDoNotDisturbPeriod(int start, int end) {
    _service.setDoNotDisturbStart(start);
    _service.setDoNotDisturbEnd(end);
    state = state.copyWith(doNotDisturbStart: start, doNotDisturbEnd: end);
  }

  void setPermissionMode(String value) {
    _service.setPermissionMode(value);
    state = state.copyWith(permissionMode: value);
  }

  void setUsername(String value) {
    _service.setUsername(value);
    state = state.copyWith(username: value);
  }

  void setEmail(String value) {
    _service.setEmail(value);
    state = state.copyWith(email: value);
  }

  void setExperiments(bool value) {
    _service.setExperiments(value);
    state = state.copyWith(experiments: value);
  }

  void setUseEnhancedSessionWizard(bool value) {
    _service.setUseEnhancedSessionWizard(value);
    state = state.copyWith(useEnhancedSessionWizard: value);
  }

  void setHideInactiveSessions(bool value) {
    _service.setHideInactiveSessions(value);
    state = state.copyWith(hideInactiveSessions: value);
  }

  void setCommandPaletteEnabled(bool value) {
    _service.setCommandPaletteEnabled(value);
    state = state.copyWith(commandPaletteEnabled: value);
  }

  void setMarkdownCopyV2(bool value) {
    _service.setMarkdownCopyV2(value);
    state = state.copyWith(markdownCopyV2: value);
  }

  void setAgentInputEnterToSend(bool value) {
    _service.setAgentInputEnterToSend(value);
    state = state.copyWith(agentInputEnterToSend: value);
  }

  void setVoiceAssistantLanguage(String? value) {
    _service.setVoiceAssistantLanguage(value);
    state = state.copyWith(voiceAssistantLanguage: value);
  }

  void setLastUsedAgent(String? value) {
    _service.setLastUsedAgent(value);
    state = state.copyWith(lastUsedAgent: value);
  }

  void setLastUsedProfile(String? value) {
    _service.setLastUsedProfile(value);
    state = state.copyWith(lastUsedProfile: value);
  }

  void setLastUsedPermissionMode(String? value) {
    _service.setLastUsedPermissionMode(value);
    state = state.copyWith(lastUsedPermissionMode: value);
  }

  void setLastUsedModelMode(String? value) {
    _service.setLastUsedModelMode(value);
    state = state.copyWith(lastUsedModelMode: value);
  }

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    state = const SettingsState();
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService.instance;
});

final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});
