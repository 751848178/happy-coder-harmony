import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/session_project_repository_service.dart';
import '../domain/session_git_models.dart';
import 'session_git_diff_screen.dart';

part 'session_files_browser_screen_content.dart';
part 'session_files_browser_screen_entries.dart';
part 'session_files_browser_screen_panels.dart';
part 'session_files_browser_screen_support.dart';
part 'session_files_browser_screen_tiles.dart';

class SessionFilesBrowserScreen extends ConsumerStatefulWidget {
  const SessionFilesBrowserScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionFilesBrowserScreen> createState() =>
      _SessionFilesBrowserScreenState();
}

class _SessionFilesBrowserScreenState
    extends ConsumerState<SessionFilesBrowserScreen> {
  final SessionProjectRepositoryService _repositoryService =
      SessionProjectRepositoryService();
  final TextEditingController _searchController = TextEditingController();

  SessionProjectRepositoryData? _data;
  Session? _session;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _loadFiles() async {
    _updateView(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(sessionStateProvider.notifier);
      var session = notifier.getSession(widget.sessionId);
      if (session == null) {
        await notifier.loadSessions(force: true);
        session = notifier.getSession(widget.sessionId);
      }
      if (session == null) {
        throw Exception('未找到当前会话');
      }
      await notifier.loadSessionMessages(widget.sessionId);
      final messages =
          notifier.getSessionMessages(widget.sessionId)?.messages ?? const [];
      final data = await _repositoryService.load(
        session: session,
        messages: messages,
        notifier: notifier,
      );
      if (!mounted) {
        return;
      }
      _updateView(() {
        _session = session;
        _data = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _updateView(() {
        _error = '加载会话文件失败: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: _buildSessionFilesBrowserAppBar(this),
      body: _buildSessionFilesBrowserBody(this, _data),
    );
  }
}
