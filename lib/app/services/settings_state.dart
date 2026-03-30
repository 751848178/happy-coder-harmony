part of 'settings_service.dart';

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
    this.username = AppConfig.appName,
    this.email = 'user@example.com',
    this.experiments = false,
    this.useEnhancedSessionWizard = false,
    this.hideInactiveSessions = false,
    this.commandPaletteEnabled = true,
    this.markdownCopyV2 = false,
    this.enableBackgroundSessionRefresh = false,
    this.agentInputEnterToSend = false,
    this.voiceAssistantLanguage,
    this.lastUsedAgent,
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
  final bool enableBackgroundSessionRefresh;
  final bool agentInputEnterToSend;
  final String? voiceAssistantLanguage;
  final String? lastUsedAgent;
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
    bool? enableBackgroundSessionRefresh,
    bool? agentInputEnterToSend,
    Object? voiceAssistantLanguage = _settingsSentinel,
    Object? lastUsedAgent = _settingsSentinel,
    Object? lastUsedPermissionMode = _settingsSentinel,
    Object? lastUsedModelMode = _settingsSentinel,
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
      enableBackgroundSessionRefresh:
          enableBackgroundSessionRefresh ?? this.enableBackgroundSessionRefresh,
      agentInputEnterToSend:
          agentInputEnterToSend ?? this.agentInputEnterToSend,
      voiceAssistantLanguage: voiceAssistantLanguage == _settingsSentinel
          ? this.voiceAssistantLanguage
          : voiceAssistantLanguage as String?,
      lastUsedAgent: lastUsedAgent == _settingsSentinel
          ? this.lastUsedAgent
          : lastUsedAgent as String?,
      lastUsedPermissionMode: lastUsedPermissionMode == _settingsSentinel
          ? this.lastUsedPermissionMode
          : lastUsedPermissionMode as String?,
      lastUsedModelMode: lastUsedModelMode == _settingsSentinel
          ? this.lastUsedModelMode
          : lastUsedModelMode as String?,
    );
  }
}

const Object _settingsSentinel = Object();
