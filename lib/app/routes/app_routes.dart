import 'app_route_builders.dart' as builders;

class AppRoutes {
  AppRoutes._();

  static const String home = '/', homeName = 'home';
  static const String notFound = '/not-found', notFoundName = 'not-found';

  static const String auth = '/auth',
      authName = 'auth',
      login = '/login',
      loginName = 'login';
  static const String backupKeys = '/backup-keys',
      backupKeysName = 'backup-keys';
  static const String loginTest = '/login-test', loginTestName = 'login-test';
  static const String linkAccount = '/link-account',
      linkAccountName = 'link-account';
  static const String restore = '/restore',
      restoreName = 'restore',
      newFlow = '/new',
      newFlowName = 'new-flow';
  static const String restoreIndex = '/restore/index',
      restoreIndexName = 'restore-index';
  static const String restoreManual = '/restore/manual',
      restoreManualName = 'restore-manual';
  static const String terminalConnect = '/terminal/connect',
      terminalConnectName = 'terminal-connect';
  static const String terminalList = '/terminal',
      terminalListName = 'terminal-list';
  static const String terminalApproval = '/terminal/terminal-approval',
      terminalApprovalName = 'terminal-approval';

  static const String encryption = '/encryption', encryptionName = 'encryption';
  static const String socket = '/socket', socketName = 'socket';
  static const String chat = '/chat', chatName = 'chat';

  static const String sessions = '/sessions', sessionsName = 'sessions';
  static const String session = '/session', sessionName = 'session';
  static const String sessionById = '/session/:id',
      sessionByIdName = 'session-by-id';
  static const String sessionRecent = '/session/recent',
      sessionRecentName = 'session-recent';
  static const String sessionMessageDetail = '/session/:id/message/:messageId',
      sessionMessageDetailName = 'session-message-detail';
  static const String newSession = '/session/new',
      newSessionName = 'new-session';
  static const String newSessionWizard = '/session/new-wizard',
      newSessionWizardName = 'new-session-wizard';
  static const String newPickMachine = '/new/pick/machine',
      newPickMachineName = 'new-pick-machine';
  static const String newPickPath = '/new/pick/path',
      newPickPathName = 'new-pick-path';
  static const String sessionFiles = '/session/files',
      sessionFilesName = 'session-files';
  static const String sessionFilesById = '/session/:id/files',
      sessionFilesByIdName = 'session-files-by-id';
  static const String sessionGitById = '/session/:id/git',
      sessionGitByIdName = 'session-git-by-id';
  static const String sessionInfo = '/session/info',
      sessionInfoName = 'session-info';
  static const String sessionInfoById = '/session/:id/info',
      sessionInfoByIdName = 'session-info-by-id';
  static const String sessionFileById = '/session/:id/file',
      sessionFileByIdName = 'session-file-by-id';

  static const String machineDetail = '/machine/:id',
      machineDetailName = 'machine-detail';
  static const String fileViewer = '/file/view', fileViewerName = 'file-viewer';

  static const String friends = '/friends',
      friendsName = 'friends',
      inbox = '/inbox',
      inboxName = 'inbox';
  static const String friendsSearch = '/friends/search',
      friendsSearchName = 'friends-search';
  static const String userProfile = '/user/profile',
      userProfileName = 'user-profile';
  static const String userProfileById = '/user/:id',
      userProfileByIdName = 'user-profile-by-id';

  static const String settings = '/settings',
      settingsName = 'settings',
      profile = '/profile',
      profileName = 'profile';
  static const String settingsAccount = '/settings/account',
      settingsAccountName = 'settings-account';
  static const String settingsNotifications = '/settings/notifications',
      settingsNotificationsName = 'settings-notifications';
  static const String settingsAppearance = '/settings/appearance',
      settingsAppearanceName = 'settings-appearance';
  static const String settingsSecurity = '/settings/security',
      settingsSecurityName = 'settings-security';
  static const String settingsAbout = '/settings/about',
      settingsAboutName = 'settings-about';
  static const String settingsUsage = '/settings/usage',
      settingsUsageName = 'settings-usage';
  static const String settingsLanguage = '/settings/language',
      settingsLanguageName = 'settings-language';
  static const String settingsFeatures = '/settings/features',
      settingsFeaturesName = 'settings-features';
  static const String settingsVoice = '/settings/voice',
      settingsVoiceName = 'settings-voice';
  static const String settingsVoiceLanguage = '/settings/voice/language',
      settingsVoiceLanguageName = 'settings-voice-language';
  static const String settingsConnectClaude = '/settings/connect/claude',
      settingsConnectClaudeName = 'settings-connect-claude';
  static const String settingsServer = '/settings/server',
      settingsServerName = 'settings-server';
  static const String settingsInputTemplates = '/settings/input-templates',
      settingsInputTemplatesName = 'settings-input-templates';

  static const String bashTool = '/tools/bash',
      bashToolName = 'bash-tool',
      editTool = '/tools/edit',
      editToolName = 'edit-tool';
  static const String writeTool = '/tools/write',
      writeToolName = 'write-tool',
      todoTool = '/tools/todo',
      todoToolName = 'todo-tool';
  static const String mcpTool = '/tools/mcp', mcpToolName = 'mcp-tool';
  static const String globTool = '/tools/glob', globToolName = 'glob-tool';
  static const String grepTool = '/tools/grep', grepToolName = 'grep-tool';
  static const String lsTool = '/tools/ls', lsToolName = 'ls-tool';
  static const String textSelection = '/text-selection',
      textSelectionName = 'text-selection';

  static const String webview = '/webview',
      webviewName = 'webview';

  static const String artifacts = '/artifacts',
      artifactsName = 'artifacts',
      changelog = '/changelog',
      changelogName = 'changelog';
  static const String artifactDetail = '/artifacts/:id',
      artifactDetailName = 'artifact-detail';
  static const String newArtifact = '/artifacts/new',
      newArtifactName = 'new-artifact';
  static const String editArtifact = '/artifacts/edit/:id',
      editArtifactName = 'edit-artifact';

  static final String Function(String) sessionDetail = builders.sessionDetail;
  static final String Function(String) sessionDetailLegacy =
      builders.sessionDetailLegacy;
  static final String Function(String) sessionInfoDetail =
      builders.sessionInfoDetail;
  static final String Function(String) sessionFilesDetail =
      builders.sessionFilesDetail;
  static final String Function(String) sessionGitDetail =
      builders.sessionGitDetail;
  static final String Function(String) sessionFileDetail =
      builders.sessionFileDetail;
  static final String Function(String, String) sessionMessage =
      builders.sessionMessage;
  static final String Function(String) machine = builders.machine;
  static final String Function(String) userProfileDetail =
      builders.userProfileDetail;
  static final String Function(String) userProfileDetailLegacy =
      builders.userProfileDetailLegacy;
  static final String Function(String) artifact = builders.artifact;
  static final String Function(String) editArtifactWithId =
      builders.editArtifactWithId;
  static final String Function({String? machineId, String? path})
      newPathPicker = builders.newPathPicker;
  static final String Function({
    String? machineId,
    String? path,
    String? agent,
    String? permissionMode,
    String? modelMode,
  }) newClonedSession = builders.newClonedSession;
  static final String Function({
    required String requestId,
    required String sessionId,
    required String machine,
    required String path,
    String? command,
    String? requestingApp,
  }) terminalApprovalDetail = builders.terminalApprovalDetail;
}
