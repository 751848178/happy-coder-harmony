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
      path: AppRoutes.settingsAbout,
      name: AppRoutes.settingsAboutName,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsInputTemplates,
      name: AppRoutes.settingsInputTemplatesName,
      builder: (context, state) => const InputTemplatesSettingsScreen(),
    ),
  ];
}
