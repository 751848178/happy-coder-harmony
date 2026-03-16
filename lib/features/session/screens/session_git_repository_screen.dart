import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/session_project_repository_service.dart';
import '../domain/session_files_models.dart';
import '../domain/session_git_models.dart';
import 'session_git_diff_screen.dart';

part 'session_git_repository_screen_models.dart';
part 'session_git_repository_screen_logic.dart';
part 'session_git_repository_screen_content.dart';
part 'session_git_repository_screen_tree.dart';
part 'session_git_repository_screen_folder_tile.dart';
part 'session_git_repository_screen_file_tile.dart';
part 'session_git_repository_screen_support.dart';
part 'session_git_repository_screen_chips.dart';

class SessionGitRepositoryScreen extends ConsumerStatefulWidget {
  const SessionGitRepositoryScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionGitRepositoryScreen> createState() =>
      _SessionGitRepositoryScreenState();
}

class _SessionGitRepositoryScreenState
    extends ConsumerState<SessionGitRepositoryScreen> {
  final SessionProjectRepositoryService _repositoryService =
      SessionProjectRepositoryService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedFolderIds = <String>{};

  SessionProjectRepositoryData? _data;
  Session? _session;
  bool _isLoading = true;
  String? _error;
  _RepositoryFilter _filter = _RepositoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRepository();
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

  Future<void> _loadRepository() => _loadSessionGitRepository(this);

  Future<void> _openFile(_ProjectFileEntry entry) =>
      _openSessionGitRepositoryFile(this, entry);

  @override
  Widget build(BuildContext context) => _buildSessionGitRepositoryScreen(this);
}
