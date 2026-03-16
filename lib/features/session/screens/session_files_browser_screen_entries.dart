part of 'session_files_browser_screen.dart';

List<_ChangedFileEntry> _visibleEntries(
  _SessionFilesBrowserScreenState state,
  SessionProjectRepositoryData data,
) {
  final query = state._searchController.text.trim().toLowerCase();
  final entriesByPath = <String, _ChangedFileEntry>{};
  for (final file in data.repository.stagedFiles) {
    entriesByPath.update(
      file.path,
      (existing) => existing.copyWith(staged: file),
      ifAbsent: () => _ChangedFileEntry(staged: file),
    );
  }
  for (final file in data.repository.unstagedFiles) {
    entriesByPath.update(
      file.path,
      (existing) => existing.copyWith(unstaged: file),
      ifAbsent: () => _ChangedFileEntry(unstaged: file),
    );
  }
  return entriesByPath.values.where((entry) {
    if (query.isEmpty) {
      return true;
    }
    return entry.fileName.toLowerCase().contains(query) ||
        entry.path.toLowerCase().contains(query);
  }).toList()
    ..sort((a, b) {
      final aWeight = a.unstaged != null ? 0 : 1;
      final bWeight = b.unstaged != null ? 0 : 1;
      if (aWeight != bWeight) {
        return aWeight.compareTo(bWeight);
      }
      return a.path.compareTo(b.path);
    });
}

Future<void> _openSessionFileEntry(
  _SessionFilesBrowserScreenState state,
  _ChangedFileEntry entry,
) async {
  final file = entry.primaryChange;
  if (file == null) {
    return;
  }
  await Navigator.of(state.context).push(
    MaterialPageRoute<void>(
      builder: (_) => SessionGitDiffScreen(
        sessionId: state.widget.sessionId,
        file: file,
      ),
    ),
  );
}

class _ChangedFileEntry {
  const _ChangedFileEntry({
    this.staged,
    this.unstaged,
  });

  final SessionGitFile? staged;
  final SessionGitFile? unstaged;

  _ChangedFileEntry copyWith({
    SessionGitFile? staged,
    SessionGitFile? unstaged,
  }) {
    return _ChangedFileEntry(
      staged: staged ?? this.staged,
      unstaged: unstaged ?? this.unstaged,
    );
  }

  String get path => unstaged?.path ?? staged?.path ?? '';

  String get fileName => unstaged?.fileName ?? staged?.fileName ?? path;

  int get totalAdded => (staged?.addedLines ?? 0) + (unstaged?.addedLines ?? 0);

  int get totalRemoved =>
      (staged?.removedLines ?? 0) + (unstaged?.removedLines ?? 0);

  SessionGitFile? get primaryChange {
    if (staged == null && unstaged == null) {
      return null;
    }
    final source = unstaged ?? staged!;
    return SessionGitFile(
      path: source.path,
      fileName: source.fileName,
      status: unstaged?.status ?? staged!.status,
      fileId: source.fileId,
      previousPath: unstaged?.previousPath ?? staged?.previousPath,
      isStaged: staged != null && unstaged == null,
      addedLines: totalAdded,
      removedLines: totalRemoved,
      diff: unstaged?.diff ?? staged?.diff,
      updatedAt: unstaged?.updatedAt ?? staged?.updatedAt,
    );
  }
}
