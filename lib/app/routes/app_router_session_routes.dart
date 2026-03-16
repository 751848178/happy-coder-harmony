part of 'app_router.dart';

List<RouteBase> _buildSessionRoutes() {
  return [
    GoRoute(
      path: AppRoutes.chat,
      name: AppRoutes.chatName,
      builder: (context, state) =>
          ChatScreen(sessionId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.homeName,
      builder: (context, state) => HomeScreen(
        initialTab: HomeTab.fromRouteValue(state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessions,
      name: AppRoutes.sessionsName,
      builder: (context, state) =>
          const HomeScreen(initialTab: HomeTab.sessions),
    ),
    GoRoute(
      path: AppRoutes.sessionRecent,
      name: AppRoutes.sessionRecentName,
      builder: (context, state) => const SessionRecentScreen(),
    ),
    GoRoute(
      path: AppRoutes.sessionMessageDetail,
      name: AppRoutes.sessionMessageDetailName,
      builder: (context, state) => SessionMessageDetailScreen(
        sessionId: state.pathParameters['id'] ?? '',
        messageId: state.pathParameters['messageId'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.session,
      name: AppRoutes.sessionName,
      builder: (context, state) => _buildSessionScreen(
        state.uri.queryParameters['id'],
        (id) => SessionScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionInfo,
      name: AppRoutes.sessionInfoName,
      builder: (context, state) => _buildSessionScreen(
        state.uri.queryParameters['id'],
        (id) => SessionInfoScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionFiles,
      name: AppRoutes.sessionFilesName,
      builder: (context, state) => _buildSessionScreen(
        state.uri.queryParameters['id'],
        (id) => SessionFilesBrowserScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionById,
      name: AppRoutes.sessionByIdName,
      builder: (context, state) => _buildSessionScreen(
        state.pathParameters['id'],
        (id) => SessionScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionInfoById,
      name: AppRoutes.sessionInfoByIdName,
      builder: (context, state) => _buildSessionScreen(
        state.pathParameters['id'],
        (id) => SessionInfoScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionFilesById,
      name: AppRoutes.sessionFilesByIdName,
      builder: (context, state) => _buildSessionScreen(
        state.pathParameters['id'],
        (id) => SessionFilesBrowserScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionGitById,
      name: AppRoutes.sessionGitByIdName,
      builder: (context, state) => _buildSessionScreen(
        state.pathParameters['id'],
        (id) => SessionGitRepositoryScreen(sessionId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.sessionFileById,
      name: AppRoutes.sessionFileByIdName,
      builder: (context, state) => _buildFileViewerRoute(state),
    ),
    GoRoute(
      path: AppRoutes.newSession,
      name: AppRoutes.newSessionName,
      builder: (context, state) => _buildAlignedNewFlowRoute(state),
    ),
    GoRoute(
      path: AppRoutes.newSessionWizard,
      name: AppRoutes.newSessionWizardName,
      builder: (context, state) => _buildAlignedNewFlowRoute(state),
    ),
    GoRoute(
      path: AppRoutes.newFlow,
      name: AppRoutes.newFlowName,
      builder: (context, state) => _buildAlignedNewFlowRoute(state),
    ),
    GoRoute(
      path: '/new/index',
      builder: (context, state) => _buildAlignedNewFlowRoute(state),
    ),
    GoRoute(
      path: AppRoutes.newPickMachine,
      name: AppRoutes.newPickMachineName,
      builder: (context, state) => SessionMachinePickerScreen(
        selectedMachineId: state.uri.queryParameters['selectedMachineId'] ??
            state.uri.queryParameters['machineId'],
      ),
    ),
    GoRoute(
      path: AppRoutes.newPickPath,
      name: AppRoutes.newPickPathName,
      builder: (context, state) => SessionPathPickerScreen(
        machineId: state.uri.queryParameters['machineId'],
        initialPath: state.uri.queryParameters['path'],
      ),
    ),
    GoRoute(
      path: AppRoutes.newPickProfileEdit,
      name: AppRoutes.newPickProfileEditName,
      builder: (context, state) => SessionProfileEditScreen(
        selectedProfileId: state.uri.queryParameters['profileId'],
        agent: state.uri.queryParameters['agent'],
      ),
    ),
    GoRoute(
      path: AppRoutes.machineDetail,
      name: AppRoutes.machineDetailName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.pathParameters['id'],
        (id) => MachineDetailScreen(machineId: id),
      ),
    ),
  ];
}
