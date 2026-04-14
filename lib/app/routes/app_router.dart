import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../shared/models/auth_state.dart';
import '../../features/artifacts/screens/artifact_detail_screen.dart';
import '../../features/artifacts/screens/artifacts_list_screen.dart';
import '../../features/artifacts/screens/edit_artifact_screen.dart';
import '../../features/artifacts/screens/new_artifact_screen.dart';
import '../../features/auth/presentation/key_backup_screen.dart';
import '../../features/auth/presentation/link_account_screen.dart';
import '../../features/auth/presentation/login_test_screen.dart';
import '../../features/auth/presentation/manual_restore_screen.dart';
import '../../features/auth/presentation/qr_code_screen.dart';
import '../../features/auth/presentation/qr_login_screen.dart';
import '../../features/auth/presentation/terminal_connect_screen.dart';
import '../../features/changelog/screens/changelog_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/encryption/presentation/encryption_screen.dart';
import '../../features/file_viewer/file_viewer_screen.dart';
import '../../features/friends/screens/friends_list_screen.dart';
import '../../features/friends/screens/friends_search_screen.dart';
import '../../features/friends/screens/inbox_screen.dart';
import '../../features/friends/screens/user_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/machine_detail_screen.dart';
import '../../features/session/screens/new_session_flow_screen.dart';
import '../../features/session/screens/session_files_browser_screen.dart';
import '../../features/session/screens/session_git_repository_screen.dart';
import '../../features/session/screens/session_info_screen.dart';
import '../../features/session/screens/session_machine_picker_screen.dart';
import '../../features/session/screens/session_message_detail_screen.dart';
import '../../features/session/screens/session_path_picker_screen.dart';
import '../../features/session/screens/session_recent_screen.dart';
import '../../features/session/screens/session_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/account_settings_screen.dart';
import '../../features/settings/screens/features_settings_screen.dart';
import '../../features/settings/screens/input_templates_settings_screen.dart';
import '../../features/settings/screens/server_settings_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/socketio/presentation/socket_connection_screen.dart';
import '../../features/terminal/screens/terminal_approval_screen.dart';
import '../../features/tools/bash_tool_screen.dart';
import '../../features/tools/edit_tool_screen.dart';
import '../../features/tools/glob_tool_screen.dart';
import '../../features/tools/grep_tool_screen.dart';
import '../../features/tools/ls_tool_screen.dart';
import '../../features/tools/mcp_tool_screen.dart';
import '../../features/tools/text_selection_screen.dart';
import '../../features/tools/todo_tool_screen.dart';
import '../../features/tools/write_tool_screen.dart';
import '../../features/webview/screens/webview_screen.dart';
import '../providers/app_providers.dart' hide NotFoundScreen;
import 'app_routes.dart';
import 'not_found_screen.dart';

part 'app_router_helpers.dart';
part 'app_router_auth_routes.dart';
part 'app_router_session_routes.dart';
part 'app_router_artifact_routes.dart';
part 'app_router_settings_routes.dart';
part 'app_router_profile_friend_routes.dart';
part 'app_router_tool_misc_routes.dart';

/// 应用路由配置
///
/// 定义所有路由和导航结构
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: AppConfig.logLevel != LogLevel.none,
    redirect: (context, state) => _redirectForAuth(authState, state),
    routes: [
      ..._buildAuthRoutes(),
      ..._buildSessionRoutes(),
      ..._buildArtifactRoutes(),
      ..._buildSettingsRoutes(),
      ..._buildProfileAndFriendRoutes(),
      ..._buildToolAndMiscRoutes(),
    ],
    errorBuilder: (context, state) => NotFoundScreen(error: state.error),
  );
});
