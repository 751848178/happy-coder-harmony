import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../features/encryption/data/encryption_repository.dart';
import '../../features/encryption/domain/encryption_service.dart';
import '../../features/auth/presentation/qr_code_screen.dart';
import '../../features/auth/presentation/qr_login_screen.dart';
import '../../features/auth/presentation/key_backup_screen.dart';
import '../../features/auth/presentation/login_test_screen.dart';
import '../../features/auth/presentation/link_account_screen.dart';
import '../../features/auth/presentation/manual_restore_screen.dart';
import '../../features/auth/presentation/terminal_connect_screen.dart';
import '../../features/socketio/presentation/socket_connection_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/changelog/screens/changelog_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/account_settings_screen.dart';
import '../../features/settings/screens/notifications_settings_screen.dart';
import '../../features/settings/screens/appearance_settings_screen.dart';
import '../../features/settings/screens/features_settings_screen.dart';
import '../../features/settings/screens/security_settings_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/usage_statistics_screen.dart';
import '../../features/settings/screens/language_settings_screen.dart';
import '../../features/settings/screens/voice_settings_screen.dart';
import '../../features/settings/screens/voice_language_settings_screen.dart';
import '../../features/settings/screens/claude_connect_screen.dart';
import '../../features/settings/screens/server_settings_screen.dart';
import '../../features/friends/screens/friends_list_screen.dart';
import '../../features/friends/screens/friends_search_screen.dart';
import '../../features/friends/screens/user_profile_screen.dart';
import '../../features/friends/screens/inbox_screen.dart';
import '../../features/profile/screens/profile_detail_screen.dart';
import '../../features/tools/text_selection_screen.dart';
import '../../features/tools/bash_tool_screen.dart';
import '../../features/tools/edit_tool_screen.dart';
import '../../features/tools/write_tool_screen.dart';
import '../../features/tools/todo_tool_screen.dart';
import '../../features/tools/mcp_tool_screen.dart';
import '../../features/tools/glob_tool_screen.dart';
import '../../features/tools/grep_tool_screen.dart';
import '../../features/tools/ls_tool_screen.dart';
import '../../features/artifacts/screens/artifacts_list_screen.dart';
import '../../features/artifacts/screens/artifact_detail_screen.dart';
import '../../features/artifacts/screens/edit_artifact_screen.dart';
import '../../features/artifacts/screens/new_artifact_screen.dart';
import '../../features/session/screens/session_info_screen.dart';
import '../../features/session/screens/machine_detail_screen.dart';
import '../../features/session/screens/new_session_flow_screen.dart';
import '../../features/file_viewer/file_viewer_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/session_screen.dart';
import '../../features/session/screens/session_machine_picker_screen.dart';
import '../../features/session/screens/session_message_detail_screen.dart';
import '../../features/session/screens/session_path_picker_screen.dart';
import '../../features/session/screens/session_profile_edit_screen.dart';
import '../../features/session/screens/session_recent_screen.dart';
import '../../features/session/screens/session_files_browser_screen.dart';
import '../../features/session/screens/session_git_repository_screen.dart';
import '../../features/profile/screens/profile_list_screen.dart';
import '../../features/terminal/screens/terminal_approval_screen.dart';

/// 应用路由配置
///
/// 定义所有路由和导航结构
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  Widget buildSessionRoute(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return const NotFoundScreen();
    }
    return SessionScreen(sessionId: sessionId);
  }

  Widget buildSessionInfoRoute(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return const NotFoundScreen();
    }
    return SessionInfoScreen(sessionId: sessionId);
  }

  Widget buildSessionFilesRoute(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return const NotFoundScreen();
    }
    return SessionFilesBrowserScreen(sessionId: sessionId);
  }

  Widget buildSessionGitRoute(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      return const NotFoundScreen();
    }
    return SessionGitRepositoryScreen(sessionId: sessionId);
  }

  Widget buildAlignedNewFlowRoute(GoRouterState state) {
    return NewSessionFlowScreen(
      initialMachineId: state.uri.queryParameters['machineId'],
      initialPath: state.uri.queryParameters['path'],
      initialProfileId: state.uri.queryParameters['profileId'],
      initialAgent: state.uri.queryParameters['agent'],
      initialPermissionMode: state.uri.queryParameters['permissionMode'],
      initialModelMode: state.uri.queryParameters['modelMode'],
    );
  }

  Widget buildFileViewerRoute(GoRouterState state) {
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

  final manualRestoreBuilder =
      (BuildContext context, GoRouterState state) => ManualRestoreScreen(
            authUrl: state.uri.queryParameters['url'],
          );

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: AppConfig.logLevel != LogLevel.none,
    redirect: (context, state) {
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
    },
    routes: [
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
        builder: (context, state) {
          final authUrl = state.uri.queryParameters['url'] ??
              state.uri.queryParameters['authUrl'];
          return LinkAccountScreen(authUrl: authUrl);
        },
      ),
      GoRoute(
        path: AppRoutes.restoreIndex,
        builder: (context, state) => const QRCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.restoreManual,
        builder: manualRestoreBuilder,
      ),
      GoRoute(
        path: AppRoutes.restore,
        name: AppRoutes.restoreName,
        builder: (context, state) => const QRCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.terminalConnect,
        name: AppRoutes.terminalConnectName,
        builder: (context, state) {
          final authUrl = state.uri.queryParameters['url'];
          return TerminalConnectScreen(authUrl: authUrl);
        },
      ),
      GoRoute(
        path: AppRoutes.terminalList,
        name: AppRoutes.terminalListName,
        builder: (context, state) {
          final authUrl = state.uri.queryParameters['url'];
          return TerminalConnectScreen(authUrl: authUrl);
        },
      ),
      GoRoute(
        path: '/terminal/index',
        builder: (context, state) {
          final authUrl = state.uri.queryParameters['url'];
          return TerminalConnectScreen(authUrl: authUrl);
        },
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
      GoRoute(
        path: AppRoutes.chat,
        name: AppRoutes.chatName,
        builder: (context, state) => ChatScreen(
          sessionId: state.uri.queryParameters['id'],
        ),
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
        builder: (context, state) => const HomeScreen(
          initialTab: HomeTab.sessions,
        ),
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
        builder: (context, state) =>
            buildSessionRoute(state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionInfo,
        name: AppRoutes.sessionInfoName,
        builder: (context, state) =>
            buildSessionInfoRoute(state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionFiles,
        name: AppRoutes.sessionFilesName,
        builder: (context, state) =>
            buildSessionFilesRoute(state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionById,
        name: AppRoutes.sessionByIdName,
        builder: (context, state) =>
            buildSessionRoute(state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionInfoById,
        name: AppRoutes.sessionInfoByIdName,
        builder: (context, state) =>
            buildSessionInfoRoute(state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionFilesById,
        name: AppRoutes.sessionFilesByIdName,
        builder: (context, state) =>
            buildSessionFilesRoute(state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionGitById,
        name: AppRoutes.sessionGitByIdName,
        builder: (context, state) =>
            buildSessionGitRoute(state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.sessionFileById,
        name: AppRoutes.sessionFileByIdName,
        builder: (context, state) => buildFileViewerRoute(state),
      ),
      GoRoute(
        path: AppRoutes.newSession,
        name: AppRoutes.newSessionName,
        builder: (context, state) => buildAlignedNewFlowRoute(state),
      ),
      GoRoute(
        path: AppRoutes.newSessionWizard,
        name: AppRoutes.newSessionWizardName,
        builder: (context, state) => buildAlignedNewFlowRoute(state),
      ),
      GoRoute(
        path: AppRoutes.newFlow,
        name: AppRoutes.newFlowName,
        builder: (context, state) => buildAlignedNewFlowRoute(state),
      ),
      GoRoute(
        path: '/new/index',
        builder: (context, state) => buildAlignedNewFlowRoute(state),
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
        builder: (context, state) {
          final machineId = state.pathParameters['id'];
          if (machineId == null || machineId.isEmpty) {
            return const NotFoundScreen();
          }
          return MachineDetailScreen(machineId: machineId);
        },
      ),
      GoRoute(
        path: AppRoutes.artifacts,
        name: AppRoutes.artifactsName,
        builder: (context, state) => const ArtifactsListScreen(),
      ),
      GoRoute(
        path: '/artifacts/index',
        builder: (context, state) => const ArtifactsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.artifactDetail,
        name: AppRoutes.artifactDetailName,
        builder: (context, state) {
          final artifactId = state.pathParameters['id'];
          if (artifactId == null || artifactId.isEmpty) {
            return const NotFoundScreen();
          }
          return ArtifactDetailScreen(artifactId: artifactId);
        },
      ),
      GoRoute(
        path: AppRoutes.newArtifact,
        name: AppRoutes.newArtifactName,
        builder: (context, state) => const NewArtifactScreen(),
      ),
      GoRoute(
        path: AppRoutes.editArtifact,
        name: AppRoutes.editArtifactName,
        builder: (context, state) {
          final artifactId = state.pathParameters['id'];
          if (artifactId == null || artifactId.isEmpty) {
            return const NotFoundScreen();
          }
          return EditArtifactScreen(artifactId: artifactId);
        },
      ),
      GoRoute(
        path: AppRoutes.fileViewer,
        name: AppRoutes.fileViewerName,
        builder: (context, state) => buildFileViewerRoute(state),
      ),
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
      GoRoute(
        path: AppRoutes.profiles,
        name: AppRoutes.profilesName,
        builder: (context, state) => const ProfileListScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDetail,
        name: AppRoutes.profileDetailName,
        builder: (context, state) {
          final profileId = state.uri.queryParameters['id'];
          if (profileId == null || profileId.isEmpty) {
            return const NotFoundScreen();
          }
          return ProfileDetailScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: AppRoutes.friends,
        name: AppRoutes.friendsName,
        builder: (context, state) => const FriendsListScreen(),
      ),
      GoRoute(
        path: '/friends/index',
        builder: (context, state) => const FriendsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.friendsSearch,
        name: AppRoutes.friendsSearchName,
        builder: (context, state) => const FriendsSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        name: AppRoutes.userProfileName,
        builder: (context, state) {
          final userId = state.uri.queryParameters['id'];
          if (userId == null || userId.isEmpty) {
            return const NotFoundScreen();
          }
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.userProfileById,
        name: AppRoutes.userProfileByIdName,
        builder: (context, state) {
          final userId = state.pathParameters['id'];
          if (userId == null || userId.isEmpty) {
            return const NotFoundScreen();
          }
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.inbox,
        name: AppRoutes.inboxName,
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/inbox/index',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: AppRoutes.bashTool,
        name: AppRoutes.bashToolName,
        builder: (context, state) => const BashToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.editTool,
        name: AppRoutes.editToolName,
        builder: (context, state) => const EditToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.writeTool,
        name: AppRoutes.writeToolName,
        builder: (context, state) => const WriteToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.todoTool,
        name: AppRoutes.todoToolName,
        builder: (context, state) => const TodoToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.mcpTool,
        name: AppRoutes.mcpToolName,
        builder: (context, state) => const MCPToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.globTool,
        name: AppRoutes.globToolName,
        builder: (context, state) => const GlobToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.grepTool,
        name: AppRoutes.grepToolName,
        builder: (context, state) => const GrepToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.lsTool,
        name: AppRoutes.lsToolName,
        builder: (context, state) => const LsToolScreen(),
      ),
      GoRoute(
        path: AppRoutes.textSelection,
        name: AppRoutes.textSelectionName,
        builder: (context, state) => TextSelectionScreen(
          text: state.uri.queryParameters['text'],
        ),
      ),
      GoRoute(
        path: AppRoutes.changelog,
        name: AppRoutes.changelogName,
        builder: (context, state) => const ChangelogScreen(),
      ),
      GoRoute(
        path: AppRoutes.notFound,
        name: AppRoutes.notFoundName,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => NotFoundScreen(error: state.error),
  );
});

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
  DateTime requestedAt = DateTime.now();
  if (requestedAtRaw != null && requestedAtRaw.isNotEmpty) {
    requestedAt = DateTime.tryParse(requestedAtRaw) ??
        DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(requestedAtRaw) ?? DateTime.now().millisecondsSinceEpoch,
        );
  }

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
        'Happy Coder',
    requestedAt: requestedAt,
  );
}

/// 错误页面
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面未找到'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.neutral600),
              const SizedBox(height: 16),
              Text(
                '页面不存在',
                style: TextStyle(fontSize: 18, color: AppTheme.neutral600),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 加密设置屏幕
class EncryptionScreen extends ConsumerWidget {
  const EncryptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encryptionState = ref.watch(encryptionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('加密设置'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _EncryptionStateView(state: encryptionState, ref: ref),
    );
  }
}

/// 初始状态视图
class _InitialView extends StatelessWidget {
  const _InitialView(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppTheme.brandColor),
            const SizedBox(height: 24),
            Text(
              '加密密钥未生成',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '为了保护您的数据安全，请生成加密密钥对',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(encryptionStateProvider.notifier).generateKeyPair(),
              icon: const Icon(Icons.vpn_key),
              label: const Text('生成密钥对'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 加载中视图
class _LoadingView extends StatelessWidget {
  const _LoadingView(this.isOwnKey);

  final bool isOwnKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            isOwnKey ? '正在生成密钥...' : '正在处理加密...',
            style: TextStyle(color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }
}

/// 加密状态视图
class _EncryptionStateView extends StatelessWidget {
  const _EncryptionStateView({required this.state, required this.ref});

  final EncryptionState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.isInitial) {
      return _InitialView(ref);
    } else if (state.isEncrypting) {
      return _LoadingView(state.isOwnKeyEncrypting);
    } else if (state.isHasKeys) {
      return _HasKeysView(ref);
    } else if (state.isDecrypted) {
      return _DecryptedView(state.decryptedData!, ref);
    } else if (state.isError) {
      return _ErrorView(state.errorMessage!, ref);
    }
    return _InitialView(ref);
  }
}

/// 有密钥视图
class _HasKeysView extends StatelessWidget {
  const _HasKeysView(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repository = EncryptionRepository.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandColor.withValues(alpha: 0.1),
                  AppTheme.brandColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '加密已启用',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '您的数据已使用端到端加密保护',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 密钥信息
          _SectionCard(
            title: '密钥信息',
            icon: Icons.vpn_key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('公钥',
                    repository.ownPublicKey?.substring(0, 20) ?? '未设置', '...'),
                const SizedBox(height: 12),
                _InfoRow(
                    '服务器公钥', repository.hasServerPublicKey ? '已设置' : '未设置', ''),
                const SizedBox(height: 12),
                _InfoRow('机器密钥', repository.hasMachineKey ? '已设置' : '未设置', ''),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 测试加密/解密
          _SectionCard(
            title: '测试加密',
            icon: Icons.lock_clock,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: '输入测试文本',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: 实现加密测试
                        },
                        icon: const Icon(Icons.lock),
                        label: const Text('加密'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 实现解密测试
                        },
                        icon: const Icon(Icons.lock_open),
                        label: const Text('解密'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 危险操作
          _SectionCard(
            title: '危险操作',
            icon: Icons.warning,
            iconColor: Colors.red,
            child: Column(
              children: [
                Text(
                  '清除密钥将导致无法解密您的数据！',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showClearKeysDialog(context, ref);
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('清除所有密钥'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearKeysDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除密钥'),
        content: const Text('清除所有密钥后，您将无法解密已加密的数据。此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(encryptionStateProvider.notifier).clearKeys();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }
}

/// 解密结果视图
class _DecryptedView extends StatelessWidget {
  const _DecryptedView(this.data, this.ref);

  final String data;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '解密成功',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral300),
            ),
            child: SelectableText(data),
          ),
        ],
      ),
    );
  }
}

/// 错误视图
class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message, this.ref);

  final String message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '发生错误',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 节卡片
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppTheme.brandColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, this.suffix);

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          suffix,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }
}

/// 错误页面
