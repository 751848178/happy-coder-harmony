part of 'app_router.dart';

List<RouteBase> _buildToolAndMiscRoutes() {
  return [
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
      builder: (context, state) =>
          TextSelectionScreen(text: state.uri.queryParameters['text']),
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
    GoRoute(
      path: AppRoutes.webview,
      name: AppRoutes.webviewName,
      builder: (context, state) => WebViewScreen(
        initialPath: state.uri.queryParameters['path'],
        title: state.uri.queryParameters['title'],
      ),
    ),
  ];
}
