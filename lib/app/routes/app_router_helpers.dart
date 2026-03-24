part of 'app_router.dart';

String? _redirectForAuth(AuthState authState, GoRouterState state) {
  final location = state.matchedLocation;
  const publicLocations = <String>{
    AppRoutes.home,
    AppRoutes.auth,
    AppRoutes.login,
    AppRoutes.backupKeys,
    AppRoutes.loginTest,
    AppRoutes.restore,
    AppRoutes.restoreIndex,
    AppRoutes.restoreManual,
  };

  if (!authState.isAuthenticated && !publicLocations.contains(location)) {
    return AppRoutes.home;
  }
  if (authState.isAuthenticated &&
      (location == AppRoutes.auth ||
          location == AppRoutes.restore ||
          location == AppRoutes.restoreIndex ||
          location == AppRoutes.login)) {
    return AppRoutes.home;
  }
  return null;
}

Widget _buildSessionScreen(String? sessionId, Widget Function(String) builder) {
  if (sessionId == null || sessionId.isEmpty) {
    return const NotFoundScreen();
  }
  return builder(sessionId);
}

Widget _buildAlignedNewFlowRoute(GoRouterState state) {
  return NewSessionFlowScreen(
    initialMachineId: state.uri.queryParameters['machineId'],
    initialPath: state.uri.queryParameters['path'],
    initialAgent: state.uri.queryParameters['agent'],
    initialPermissionMode: state.uri.queryParameters['permissionMode'],
    initialModelMode: state.uri.queryParameters['modelMode'],
  );
}

Widget _buildFileViewerRoute(GoRouterState state) {
  final fileId =
      state.uri.queryParameters['fileId'] ?? state.uri.queryParameters['id'];
  final sessionId =
      state.pathParameters['id'] ?? state.uri.queryParameters['sessionId'];
  final filePath = state.uri.queryParameters['path'];
  if ((fileId == null || fileId.isEmpty) &&
      (sessionId == null ||
          sessionId.isEmpty ||
          filePath == null ||
          filePath.isEmpty)) {
    return const NotFoundScreen();
  }

  final normalizedPath = filePath == null || filePath.isEmpty
      ? null
      : Uri.decodeComponent(filePath);
  final fileName = state.uri.queryParameters['name'] ??
      state.uri.queryParameters['fileName'] ??
      (normalizedPath?.split(RegExp(r'[\\/]')).last ?? 'Unknown File');

  return FileViewerScreen(
    sessionId: sessionId,
    fileId: fileId,
    fileName: fileName,
    mimeType: state.uri.queryParameters['mimeType'],
    filePath: normalizedPath,
  );
}

Widget _buildTerminalConnectRoute(GoRouterState state) {
  return TerminalConnectScreen(authUrl: state.uri.queryParameters['url']);
}

Widget _buildLinkAccountRoute(GoRouterState state) {
  final authUrl =
      state.uri.queryParameters['url'] ?? state.uri.queryParameters['authUrl'];
  return LinkAccountScreen(authUrl: authUrl);
}

Widget _buildManualRestoreRoute(GoRouterState state) {
  return ManualRestoreScreen(authUrl: state.uri.queryParameters['url']);
}

Widget _buildRequiredPathWidget(
  String? value,
  Widget Function(String) builder,
) {
  if (value == null || value.isEmpty) {
    return const NotFoundScreen();
  }
  return builder(value);
}

TerminalApprovalRequest _parseTerminalApprovalRequest(GoRouterState state) {
  final rawUrl = state.uri.queryParameters['url'];
  if (rawUrl != null && rawUrl.isNotEmpty) {
    final parsed =
        TerminalApprovalLinkParser.parse(Uri.decodeComponent(rawUrl));
    if (parsed != null) {
      return parsed;
    }
  }

  final requestedAtRaw = state.uri.queryParameters['requestedAt'];
  final requestedAt = requestedAtRaw == null || requestedAtRaw.isEmpty
      ? DateTime.now()
      : DateTime.tryParse(requestedAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(requestedAtRaw) ??
                DateTime.now().millisecondsSinceEpoch,
          );

  return TerminalApprovalRequest(
    id: state.uri.queryParameters['id'] ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    sessionId: state.uri.queryParameters['sessionId'] ??
        state.uri.queryParameters['session'] ??
        'unknown-session',
    machine: state.uri.queryParameters['machine'] ??
        state.uri.queryParameters['host'] ??
        'localhost',
    path: state.uri.queryParameters['path'] ??
        state.uri.queryParameters['dir'] ??
        '~',
    command: state.uri.queryParameters['command'],
    requestingApp: state.uri.queryParameters['requestingApp'] ??
        state.uri.queryParameters['app'] ??
        AppConfig.appName,
    requestedAt: requestedAt,
  );
}
