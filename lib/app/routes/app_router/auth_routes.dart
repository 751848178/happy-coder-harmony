part of 'app_router.dart';

List<RouteBase> _buildAuthRoutes() {
  return [
    GoRoute(
      path: AppRoutes.auth,
      name: AppRoutes.authName,
      builder: (context, state) => const QRLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.loginName,
      builder: (context, state) => const KeyBackupScreen(),
    ),
    GoRoute(
      path: AppRoutes.backupKeys,
      name: AppRoutes.backupKeysName,
      builder: (context, state) => const KeyBackupScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginTest,
      name: AppRoutes.loginTestName,
      builder: (context, state) => const LoginTestScreen(),
    ),
    GoRoute(
      path: AppRoutes.linkAccount,
      name: AppRoutes.linkAccountName,
      builder: (context, state) => _buildLinkAccountRoute(state),
    ),
    GoRoute(
      path: AppRoutes.restoreIndex,
      builder: (context, state) => const QRCodeScreen(),
    ),
    GoRoute(
      path: AppRoutes.restoreManual,
      builder: (context, state) => _buildManualRestoreRoute(state),
    ),
    GoRoute(
      path: AppRoutes.restore,
      name: AppRoutes.restoreName,
      builder: (context, state) => const QRCodeScreen(),
    ),
    GoRoute(
      path: AppRoutes.terminalConnect,
      name: AppRoutes.terminalConnectName,
      builder: (context, state) => _buildTerminalConnectRoute(state),
    ),
    GoRoute(
      path: AppRoutes.terminalList,
      name: AppRoutes.terminalListName,
      builder: (context, state) => _buildTerminalConnectRoute(state),
    ),
    GoRoute(
      path: '/terminal/index',
      builder: (context, state) => _buildTerminalConnectRoute(state),
    ),
    GoRoute(
      path: AppRoutes.terminalApproval,
      name: AppRoutes.terminalApprovalName,
      builder: (context, state) => TerminalApprovalScreen(
        request: _parseTerminalApprovalRequest(state),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsServer,
      name: AppRoutes.settingsServerName,
      builder: (context, state) => const ServerSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.encryption,
      name: AppRoutes.encryptionName,
      builder: (context, state) => const EncryptionScreen(),
    ),
    GoRoute(
      path: AppRoutes.socket,
      name: AppRoutes.socketName,
      builder: (context, state) => const SocketConnectionScreen(),
    ),
  ];
}
