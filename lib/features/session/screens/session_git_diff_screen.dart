import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/session_project_repository_service.dart';
import '../domain/session_git_models.dart';

part 'session_git_diff_screen_body.dart';
part 'session_git_diff_screen_controls.dart';
part 'session_git_diff_screen_line_widgets.dart';
part 'session_git_diff_screen_models.dart';
part 'session_git_diff_screen_parser.dart';
part 'session_git_diff_screen_summary.dart';

class SessionGitDiffScreen extends ConsumerStatefulWidget {
  const SessionGitDiffScreen({
    super.key,
    required this.sessionId,
    required this.file,
  });

  final String sessionId;
  final SessionGitFile file;

  @override
  ConsumerState<SessionGitDiffScreen> createState() =>
      _SessionGitDiffScreenState();
}

enum _GitFileDisplayMode {
  diff,
  file,
}

class _SessionGitDiffScreenState extends ConsumerState<SessionGitDiffScreen> {
  final SessionProjectRepositoryService _repositoryService =
      SessionProjectRepositoryService();

  bool _isLoading = true;
  String? _error;
  String? _diffContent;
  String? _fileContent;
  bool _isBinary = false;
  final ValueNotifier<_GitFileDisplayMode> _displayMode =
      ValueNotifier(_GitFileDisplayMode.diff);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayMode.dispose();
    super.dispose();
  }

  void _setLoadingState() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
  }

  void _setLoadedState({
    required String? diff,
    required String? fileContent,
    required bool isBinary,
  }) {
    setState(() {
      _diffContent = diff;
      _fileContent = fileContent;
      _isBinary = isBinary;
      _isLoading = false;
    });
    _displayMode.value = (diff != null && diff.trim().isNotEmpty)
        ? _GitFileDisplayMode.diff
        : _GitFileDisplayMode.file;
  }

  void _setErrorState(Object error) {
    setState(() {
      _error = '加载文件改动失败: $error';
      _isLoading = false;
    });
  }

  void _setDisplayMode(_GitFileDisplayMode mode) {
    _displayMode.value = mode;
  }

  Future<void> _load() async {
    _setLoadingState();

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

      final diffFuture = _repositoryService.loadGitDiff(
        session: session,
        notifier: notifier,
        file: widget.file,
      );
      final contentFuture = _repositoryService.readFileContent(
        session: session,
        notifier: notifier,
        filePath: widget.file.path,
      );
      final diff = await diffFuture;
      final content = await contentFuture;
      if (!mounted) {
        return;
      }

      _setLoadedState(
        diff: diff,
        fileContent: content?.content,
        isBinary: content?.isBinary ?? false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setErrorState(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = _diffContent ?? widget.file.diff ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: _SessionGitDiffAppBarTitle(file: widget.file),
        actions: _buildAppBarActions(diff),
      ),
      body: Column(
        children: [
          _DiffSummaryBar(file: widget.file),
          if ((diff).trim().isNotEmpty || _fileContent != null)
            ValueListenableBuilder<_GitFileDisplayMode>(
              valueListenable: _displayMode,
              builder: (context, mode, _) =>
                  _buildDisplayModeBar(mode: mode),
            ),
          Expanded(
            child: ValueListenableBuilder<_GitFileDisplayMode>(
              valueListenable: _displayMode,
              builder: (context, mode, _) =>
                  _SessionGitDiffBody(state: this, diff: diff, displayMode: mode),
            ),
          ),
        ],
      ),
    );
  }
}
