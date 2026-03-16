part of 'app_router.dart';

List<RouteBase> _buildSettingsRoutes() {
  return [
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settingsName,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/index',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsAccount,
      name: AppRoutes.settingsAccountName,
      builder: (context, state) => const AccountSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsNotifications,
      name: AppRoutes.settingsNotificationsName,
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsAppearance,
      name: AppRoutes.settingsAppearanceName,
      builder: (context, state) => const AppearanceSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsSecurity,
      name: AppRoutes.settingsSecurityName,
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsAbout,
      name: AppRoutes.settingsAboutName,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsUsage,
      name: AppRoutes.settingsUsageName,
      builder: (context, state) => const UsageStatisticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsLanguage,
      name: AppRoutes.settingsLanguageName,
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsFeatures,
      name: AppRoutes.settingsFeaturesName,
      builder: (context, state) => const FeaturesSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsVoice,
      name: AppRoutes.settingsVoiceName,
      builder: (context, state) => const VoiceSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsVoiceLanguage,
      name: AppRoutes.settingsVoiceLanguageName,
      builder: (context, state) => const VoiceLanguageSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsConnectClaude,
      name: AppRoutes.settingsConnectClaudeName,
      builder: (context, state) => const ClaudeConnectScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsProfiles,
      name: AppRoutes.settingsProfilesName,
      builder: (context, state) => const ProfileListScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: AppRoutes.profileName,
      builder: (context, state) => const ProfileScreen(),
    ),
  ];
}
