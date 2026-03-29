part of 'settings_service.dart';

extension SettingsServiceAccessors on SettingsService {
  bool get isDarkMode => _getBool(SettingsService._keyDarkMode, false);
  Future<void> setDarkMode(bool value) =>
      _setBool(SettingsService._keyDarkMode, value);

  String get colorTheme => _getString(SettingsService._keyColorTheme, 'brand');
  Future<void> setColorTheme(String value) =>
      _setString(SettingsService._keyColorTheme, value);

  double get fontSize => _getDouble(SettingsService._keyFontSize, 1.0);
  Future<void> setFontSize(double value) =>
      _setDouble(SettingsService._keyFontSize, value);

  bool get enableNotifications =>
      _getBool(SettingsService._keyEnableNotifications, true);
  Future<void> setEnableNotifications(bool value) =>
      _setBool(SettingsService._keyEnableNotifications, value);

  bool get enableSound => _getBool(SettingsService._keyEnableSound, true);
  Future<void> setEnableSound(bool value) =>
      _setBool(SettingsService._keyEnableSound, value);

  bool get enableVibration =>
      _getBool(SettingsService._keyEnableVibration, true);
  Future<void> setEnableVibration(bool value) =>
      _setBool(SettingsService._keyEnableVibration, value);

  bool get enableMessageNotifications =>
      _getBool(SettingsService._keyEnableMessageNotifications, true);
  Future<void> setEnableMessageNotifications(bool value) =>
      _setBool(SettingsService._keyEnableMessageNotifications, value);

  bool get enableSystemNotifications =>
      _getBool(SettingsService._keyEnableSystemNotifications, true);
  Future<void> setEnableSystemNotifications(bool value) =>
      _setBool(SettingsService._keyEnableSystemNotifications, value);

  bool get enableErrorNotifications =>
      _getBool(SettingsService._keyEnableErrorNotifications, true);
  Future<void> setEnableErrorNotifications(bool value) =>
      _setBool(SettingsService._keyEnableErrorNotifications, value);

  int get doNotDisturbStart =>
      _getInt(SettingsService._keyDoNotDisturbStart, 22);
  Future<void> setDoNotDisturbStart(int value) =>
      _setInt(SettingsService._keyDoNotDisturbStart, value);

  int get doNotDisturbEnd => _getInt(SettingsService._keyDoNotDisturbEnd, 8);
  Future<void> setDoNotDisturbEnd(int value) =>
      _setInt(SettingsService._keyDoNotDisturbEnd, value);

  String get permissionMode =>
      _getString(SettingsService._keyPermissionMode, 'manual');
  Future<void> setPermissionMode(String value) =>
      _setString(SettingsService._keyPermissionMode, value);

  String get username =>
      _getString(SettingsService._keyUsername, AppConfig.appName);
  Future<void> setUsername(String value) =>
      _setString(SettingsService._keyUsername, value);

  String get email => _getString(SettingsService._keyEmail, 'user@example.com');
  Future<void> setEmail(String value) =>
      _setString(SettingsService._keyEmail, value);

  bool get experiments => _getBool(SettingsService._keyExperiments, false);
  Future<void> setExperiments(bool value) =>
      _setBool(SettingsService._keyExperiments, value);

  bool get useEnhancedSessionWizard =>
      _getBool(SettingsService._keyUseEnhancedSessionWizard, false);
  Future<void> setUseEnhancedSessionWizard(bool value) =>
      _setBool(SettingsService._keyUseEnhancedSessionWizard, value);

  bool get hideInactiveSessions =>
      _getBool(SettingsService._keyHideInactiveSessions, false);
  Future<void> setHideInactiveSessions(bool value) =>
      _setBool(SettingsService._keyHideInactiveSessions, value);

  bool get commandPaletteEnabled =>
      _getBool(SettingsService._keyCommandPaletteEnabled, true);
  Future<void> setCommandPaletteEnabled(bool value) =>
      _setBool(SettingsService._keyCommandPaletteEnabled, value);

  bool get markdownCopyV2 =>
      _getBool(SettingsService._keyMarkdownCopyV2, false);
  Future<void> setMarkdownCopyV2(bool value) =>
      _setBool(SettingsService._keyMarkdownCopyV2, value);

  bool get enableBackgroundSessionRefresh =>
      _getBool(SettingsService._keyEnableBackgroundSessionRefresh, false);
  Future<void> setEnableBackgroundSessionRefresh(bool value) =>
      _setBool(SettingsService._keyEnableBackgroundSessionRefresh, value);

  bool get agentInputEnterToSend =>
      _getBool(SettingsService._keyAgentInputEnterToSend, false);
  Future<void> setAgentInputEnterToSend(bool value) =>
      _setBool(SettingsService._keyAgentInputEnterToSend, value);

  String? get voiceAssistantLanguage =>
      _getNullableString(SettingsService._keyVoiceAssistantLanguage);
  Future<void> setVoiceAssistantLanguage(String? value) =>
      _setNullableString(SettingsService._keyVoiceAssistantLanguage, value);

  String? get lastUsedAgent =>
      _getNullableString(SettingsService._keyLastUsedAgent);
  Future<void> setLastUsedAgent(String? value) =>
      _setNullableString(SettingsService._keyLastUsedAgent, value);

  String? get lastUsedPermissionMode =>
      _getNullableString(SettingsService._keyLastUsedPermissionMode);
  Future<void> setLastUsedPermissionMode(String? value) =>
      _setNullableString(SettingsService._keyLastUsedPermissionMode, value);

  String? get lastUsedModelMode =>
      _getNullableString(SettingsService._keyLastUsedModelMode);
  Future<void> setLastUsedModelMode(String? value) =>
      _setNullableString(SettingsService._keyLastUsedModelMode, value);
}
