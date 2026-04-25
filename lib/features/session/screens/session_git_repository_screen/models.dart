part of 'session_git_repository_screen.dart';

enum _RepositoryFilter {
  all,
  changed,
  staged,
  unstaged,
}

class _ProjectFileEntry {
  const _ProjectFileEntry({
    required this.file,
    this.staged,
    this.unstaged,
  });

  factory _ProjectFileEntry.fromGitFile(SessionGitFile file) {
    return _ProjectFileEntry(
      file: SessionFile(
        id: 'changed:${file.path}',
        sessionId: '',
        filePath: file.path,
        fileName: file.fileName,
        createdAt: 0,
        updatedAt: file.updatedAt?.millisecondsSinceEpoch ?? 0,
      ),
      staged: file.isStaged ? file : null,
      unstaged: file.isStaged ? null : file,
    );
  }

  final SessionFile file;
  final SessionGitFile? staged;
  final SessionGitFile? unstaged;

  bool get isChanged => staged != null || unstaged != null;

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
      addedLines: (staged?.addedLines ?? 0) + (unstaged?.addedLines ?? 0),
      removedLines: (staged?.removedLines ?? 0) + (unstaged?.removedLines ?? 0),
      diff: unstaged?.diff ?? staged?.diff,
      updatedAt: unstaged?.updatedAt ?? staged?.updatedAt,
    );
  }
}

class _RepositoryTreeNode {
  _RepositoryTreeNode.directory({
    required this.id,
    required this.name,
  })  : entry = null,
        children = <String, _RepositoryTreeNode>{},
        _sortedChildren = const [];

  _RepositoryTreeNode.file({
    required this.id,
    required this.name,
    required this.entry,
  })  : children = const <String, _RepositoryTreeNode>{},
        _sortedChildren = const [];

  final String id;
  final String name;
  final _ProjectFileEntry? entry;
  final Map<String, _RepositoryTreeNode> children;
  List<_RepositoryTreeNode> _sortedChildren;

  bool get isDirectory => entry == null;
  bool get isChanged => entry?.isChanged == true;
  int get changedCount => isDirectory
      ? sortedChildren.fold<int>(0, (sum, child) => sum + child.changedCount)
      : (isChanged ? 1 : 0);
  int get fileCount => isDirectory
      ? sortedChildren.fold<int>(0, (sum, child) => sum + child.fileCount)
      : 1;
  List<_RepositoryTreeNode> get sortedChildren => _sortedChildren;

  void replaceChildren(List<_RepositoryTreeNode> next) {
    _sortedChildren = next;
  }
}
