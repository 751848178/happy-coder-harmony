/// 应用路由常量
///
/// 统一管理所有路由路径和名称，同时兼容当前项目已有的 query 风格路径
/// 与上游 Happy Coder 的动态路径风格。
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String homeName = 'home';
  static const String notFound = '/not-found';
  static const String notFoundName = 'not-found';

  static const String auth = '/auth';
  static const String authName = 'auth';
  static const String login = '/login';
  static const String loginName = 'login';
  static const String backupKeys = '/backup-keys';
  static const String backupKeysName = 'backup-keys';
  static const String loginTest = '/login-test';
  static const String loginTestName = 'login-test';
  static const String linkAccount = '/link-account';
  static const String linkAccountName = 'link-account';
  static const String restore = '/restore';
  static const String restoreName = 'restore';
  static const String restoreIndex = '/restore/index';
  static const String restoreIndexName = 'restore-index';
  static const String restoreManual = '/restore/manual';
  static const String restoreManualName = 'restore-manual';
  static const String terminalConnect = '/terminal/connect';
  static const String terminalConnectName = 'terminal-connect';
  static const String terminalList = '/terminal';
  static const String terminalListName = 'terminal-list';
  static const String terminalApproval = '/terminal/terminal-approval';
  static const String terminalApprovalName = 'terminal-approval';

  static const String encryption = '/encryption';
  static const String encryptionName = 'encryption';

  static const String socket = '/socket';
  static const String socketName = 'socket';

  static const String chat = '/chat';
  static const String chatName = 'chat';

  static const String sessions = '/sessions';
  static const String sessionsName = 'sessions';
  static const String session = '/session';
  static const String sessionName = 'session';
  static const String sessionById = '/session/:id';
  static const String sessionByIdName = 'session-by-id';
  static const String sessionRecent = '/session/recent';
  static const String sessionRecentName = 'session-recent';
  static const String sessionMessageDetail = '/session/:id/message/:messageId';
  static const String sessionMessageDetailName = 'session-message-detail';
  static const String newSession = '/session/new';
  static const String newSessionName = 'new-session';
  static const String newSessionWizard = '/session/new-wizard';
  static const String newSessionWizardName = 'new-session-wizard';
  static const String newFlow = '/new';
  static const String newFlowName = 'new-flow';
  static const String newPickMachine = '/new/pick/machine';
  static const String newPickMachineName = 'new-pick-machine';
  static const String newPickPath = '/new/pick/path';
  static const String newPickPathName = 'new-pick-path';
  static const String newPickProfileEdit = '/new/pick/profile-edit';
  static const String newPickProfileEditName = 'new-pick-profile-edit';
  static const String sessionFiles = '/session/files';
  static const String sessionFilesName = 'session-files';
  static const String sessionFilesById = '/session/:id/files';
  static const String sessionFilesByIdName = 'session-files-by-id';
  static const String sessionGitById = '/session/:id/git';
  static const String sessionGitByIdName = 'session-git-by-id';
  static const String sessionInfo = '/session/info';
  static const String sessionInfoName = 'session-info';
  static const String sessionInfoById = '/session/:id/info';
  static const String sessionInfoByIdName = 'session-info-by-id';
  static const String sessionFileById = '/session/:id/file';
  static const String sessionFileByIdName = 'session-file-by-id';

  static const String machineDetail = '/machine/:id';
  static const String machineDetailName = 'machine-detail';

  static const String fileViewer = '/file/view';
  static const String fileViewerName = 'file-viewer';

  static const String friends = '/friends';
  static const String friendsName = 'friends';
  static const String friendsSearch = '/friends/search';
  static const String friendsSearchName = 'friends-search';
  static const String userProfile = '/user/profile';
  static const String userProfileName = 'user-profile';
  static const String userProfileById = '/user/:id';
  static const String userProfileByIdName = 'user-profile-by-id';

  static const String inbox = '/inbox';
  static const String inboxName = 'inbox';

  static const String settings = '/settings';
  static const String settingsName = 'settings';
  static const String settingsAccount = '/settings/account';
  static const String settingsAccountName = 'settings-account';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsNotificationsName = 'settings-notifications';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsAppearanceName = 'settings-appearance';
  static const String settingsSecurity = '/settings/security';
  static const String settingsSecurityName = 'settings-security';
  static const String settingsAbout = '/settings/about';
  static const String settingsAboutName = 'settings-about';
  static const String settingsUsage = '/settings/usage';
  static const String settingsUsageName = 'settings-usage';
  static const String settingsLanguage = '/settings/language';
  static const String settingsLanguageName = 'settings-language';
  static const String settingsFeatures = '/settings/features';
  static const String settingsFeaturesName = 'settings-features';
  static const String settingsVoice = '/settings/voice';
  static const String settingsVoiceName = 'settings-voice';
  static const String settingsVoiceLanguage = '/settings/voice/language';
  static const String settingsVoiceLanguageName = 'settings-voice-language';
  static const String settingsConnectClaude = '/settings/connect/claude';
  static const String settingsConnectClaudeName = 'settings-connect-claude';
  static const String settingsServer = '/settings/server';
  static const String settingsServerName = 'settings-server';
  static const String settingsProfiles = '/settings/profiles';
  static const String settingsProfilesName = 'settings-profiles';

  static const String profile = '/profile';
  static const String profileName = 'profile';
  static const String profiles = '/profiles';
  static const String profilesName = 'profiles';
  static const String profileDetail = '/profile/detail';
  static const String profileDetailName = 'profile-detail';

  static const String bashTool = '/tools/bash';
  static const String bashToolName = 'bash-tool';
  static const String editTool = '/tools/edit';
  static const String editToolName = 'edit-tool';
  static const String writeTool = '/tools/write';
  static const String writeToolName = 'write-tool';
  static const String todoTool = '/tools/todo';
  static const String todoToolName = 'todo-tool';
  static const String mcpTool = '/tools/mcp';
  static const String mcpToolName = 'mcp-tool';
  static const String globTool = '/tools/glob';
  static const String globToolName = 'glob-tool';
  static const String grepTool = '/tools/grep';
  static const String grepToolName = 'grep-tool';
  static const String lsTool = '/tools/ls';
  static const String lsToolName = 'ls-tool';
  static const String textSelection = '/text-selection';
  static const String textSelectionName = 'text-selection';

  static const String artifacts = '/artifacts';
  static const String artifactsName = 'artifacts';
  static const String artifactDetail = '/artifacts/:id';
  static const String artifactDetailName = 'artifact-detail';
  static const String newArtifact = '/artifacts/new';
  static const String newArtifactName = 'new-artifact';
  static const String editArtifact = '/artifacts/edit/:id';
  static const String editArtifactName = 'edit-artifact';

  static const String changelog = '/changelog';
  static const String changelogName = 'changelog';

  static String sessionDetail(String sessionId) => '/session/$sessionId';
  static String sessionDetailLegacy(String sessionId) =>
      '/session?id=$sessionId';
  static String sessionInfoDetail(String sessionId) =>
      '/session/$sessionId/info';
  static String sessionFilesDetail(String sessionId) =>
      '/session/$sessionId/files';
  static String sessionGitDetail(String sessionId) => '/session/$sessionId/git';
  static String sessionFileDetail(String sessionId) =>
      '/session/$sessionId/file';
  static String sessionMessage(String sessionId, String messageId) =>
      '/session/$sessionId/message/$messageId';

  static String machine(String machineId) => '/machine/$machineId';
  static String userProfileDetail(String userId) => '/user/$userId';
  static String userProfileDetailLegacy(String userId) =>
      '/user/profile?id=$userId';
  static String profileDetailWithId(String profileId) =>
      '/profile/detail?id=$profileId';
  static String artifact(String artifactId) => '/artifacts/$artifactId';
  static String editArtifactWithId(String artifactId) =>
      '/artifacts/edit/$artifactId';
  static String newPathPicker({String? machineId, String? path}) {
    final query = <String, String>{
      if (machineId != null && machineId.isNotEmpty) 'machineId': machineId,
      if (path != null && path.isNotEmpty) 'path': path,
    };
    final uri =
        Uri(path: newPickPath, queryParameters: query.isEmpty ? null : query);
    return uri.toString();
  }

  static String newProfilePicker({String? profileId, String? agent}) {
    final query = <String, String>{
      if (profileId != null && profileId.isNotEmpty) 'profileId': profileId,
      if (agent != null && agent.isNotEmpty) 'agent': agent,
    };
    final uri = Uri(
        path: newPickProfileEdit,
        queryParameters: query.isEmpty ? null : query);
    return uri.toString();
  }

  static String newClonedSession({
    String? machineId,
    String? path,
    String? profileId,
    String? agent,
    String? permissionMode,
    String? modelMode,
  }) {
    final query = <String, String>{
      if (machineId != null && machineId.isNotEmpty) 'machineId': machineId,
      if (path != null && path.isNotEmpty) 'path': path,
      if (profileId != null && profileId.isNotEmpty) 'profileId': profileId,
      if (agent != null && agent.isNotEmpty) 'agent': agent,
      if (permissionMode != null && permissionMode.isNotEmpty)
        'permissionMode': permissionMode,
      if (modelMode != null && modelMode.isNotEmpty) 'modelMode': modelMode,
    };
    return Uri(
      path: newFlow,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String terminalApprovalDetail({
    required String requestId,
    required String sessionId,
    required String machine,
    required String path,
    String? command,
    String? requestingApp,
  }) {
    final uri = Uri(
      path: terminalApproval,
      queryParameters: <String, String>{
        'id': requestId,
        'sessionId': sessionId,
        'machine': machine,
        'path': path,
        if (command != null && command.isNotEmpty) 'command': command,
        if (requestingApp != null && requestingApp.isNotEmpty)
          'requestingApp': requestingApp,
      },
    );
    return uri.toString();
  }
}
