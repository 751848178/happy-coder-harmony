part of 'settings_service.dart';

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
      enableBackgroundSessionRefresh: _service.enableBackgroundSessionRefresh,
      agentInputEnterToSend: _service.agentInputEnterToSend,
      voiceAssistantLanguage: _service.voiceAssistantLanguage,
      lastUsedAgent: _service.lastUsedAgent,
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

  void setEnableBackgroundSessionRefresh(bool value) {
    _service.setEnableBackgroundSessionRefresh(value);
    state = state.copyWith(enableBackgroundSessionRefresh: value);
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
