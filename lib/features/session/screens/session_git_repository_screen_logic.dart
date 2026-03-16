part of 'session_git_repository_screen.dart';

Future<void> _loadSessionGitRepository(
  _SessionGitRepositoryScreenState state,
) async {
  state._updateView(() {
    state._isLoading = true;
    state._error = null;
  });

  try {
    final notifier = state.ref.read(sessionStateProvider.notifier);
    var session = notifier.getSession(state.widget.sessionId);
    if (session == null) {
      await notifier.loadSessions(force: true);
      session = notifier.getSession(state.widget.sessionId);
    }
    if (session == null) {
      throw Exception('未找到当前会话');
    }

    await notifier.loadSessionMessages(state.widget.sessionId);
    final messages =
        notifier.getSessionMessages(state.widget.sessionId)?.messages ??
            const [];
    final data = await state._repositoryService.load(
      session: session,
      messages: messages,
      notifier: notifier,
    );

    state._updateView(() {
      state._session = session;
      state._data = data;
      state._isLoading = false;
    });
  } catch (error) {
    state._updateView(() {
      state._error = '加载 Git 仓库失败: $error';
      state._isLoading = false;
    });
  }
}

List<_ProjectFileEntry> _visibleRepositoryFiles(
  _SessionGitRepositoryScreenState state,
  SessionProjectRepositoryData data,
) {
  final query = state._searchController.text.trim().toLowerCase();
  final stagedByPath = <String, SessionGitFile>{
    for (final file in data.repository.stagedFiles) file.path: file,
  };
  final unstagedByPath = <String, SessionGitFile>{
    for (final file in data.repository.unstagedFiles) file.path: file,
  };
  final allEntriesByPath = <String, _ProjectFileEntry>{};

  for (final file in data.projectFiles) {
    allEntriesByPath[file.filePath] = _ProjectFileEntry(
      file: file,
      staged: stagedByPath[file.filePath],
      unstaged: unstagedByPath[file.filePath],
    );
  }
  for (final file in data.repository.changedFiles) {
    allEntriesByPath.putIfAbsent(
        file.path, () => _ProjectFileEntry.fromGitFile(file));
  }

  final allEntries = allEntriesByPath.values.toList()
    ..sort((a, b) {
      final aChanged = a.isChanged ? 0 : 1;
      final bChanged = b.isChanged ? 0 : 1;
      if (aChanged != bChanged) {
        return aChanged.compareTo(bChanged);
      }
      return a.file.filePath.compareTo(b.file.filePath);
    });

  final filtered = allEntries.where((entry) {
    final matchesQuery = query.isEmpty ||
        entry.file.fileName.toLowerCase().contains(query) ||
        entry.file.filePath.toLowerCase().contains(query);
    if (!matchesQuery) {
      return false;
    }
    switch (state._filter) {
      case _RepositoryFilter.all:
        return true;
      case _RepositoryFilter.changed:
        return entry.isChanged;
      case _RepositoryFilter.staged:
        return entry.staged != null;
      case _RepositoryFilter.unstaged:
        return entry.unstaged != null;
    }
  }).toList();

  if (state._filter == _RepositoryFilter.changed &&
      filtered.isEmpty &&
      query.isEmpty) {
    return [
      ...data.repository.stagedFiles.map(_ProjectFileEntry.fromGitFile),
      ...data.repository.unstagedFiles.map(_ProjectFileEntry.fromGitFile),
    ];
  }
  return filtered;
}

Future<void> _openSessionGitRepositoryFile(
  _SessionGitRepositoryScreenState state,
  _ProjectFileEntry entry,
) async {
  final changedFile = entry.primaryChange;
  if (changedFile != null) {
    await Navigator.of(state.context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionGitDiffScreen(
          sessionId: state.widget.sessionId,
          file: changedFile,
        ),
      ),
    );
    return;
  }

  final uri = Uri(
    path: AppRoutes.sessionFileDetail(state.widget.sessionId),
    queryParameters: {
      'fileId': entry.file.id,
      'path': entry.file.filePath,
      'name': entry.file.fileName,
      if (entry.file.mimeType != null && entry.file.mimeType!.isNotEmpty)
        'mimeType': entry.file.mimeType!,
    },
  );
  await state.context.push(uri.toString());
}
