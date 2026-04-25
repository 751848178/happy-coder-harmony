part of 'settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService.instance;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.init();
  });
  return service;
});

final settingsStateProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});
