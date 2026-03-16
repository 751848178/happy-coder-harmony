part of 'session_git_repository_screen.dart';

List<Widget> _buildRepositoryTreeWidgets(
  _SessionGitRepositoryScreenState state,
  List<_RepositoryTreeNode> nodes, {
  required int depth,
  required bool forceExpandAll,
}) {
  final widgets = <Widget>[];
  for (final node in nodes) {
    if (node.isDirectory) {
      final expanded = forceExpandAll ||
          depth == 0 ||
          state._expandedFolderIds.contains(node.id);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RepositoryFolderTile(
            node: node,
            depth: depth,
            expanded: expanded,
            onTap: () =>
                _toggleRepositoryFolder(state, node.id, expanded: expanded),
          ),
        ),
      );
      if (expanded) {
        widgets.addAll(
          _buildRepositoryTreeWidgets(
            state,
            node.sortedChildren,
            depth: depth + 1,
            forceExpandAll: forceExpandAll,
          ),
        );
      }
      continue;
    }

    final entry = node.entry!;
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ProjectTreeFileTile(
          entry: entry,
          depth: depth,
          onTap: () => state._openFile(entry),
        ),
      ),
    );
  }
  return widgets;
}

List<_RepositoryTreeNode> _buildRepositoryTreeNodes(
    List<_ProjectFileEntry> entries) {
  final roots = <String, _RepositoryTreeNode>{};
  for (final entry in entries) {
    final segments = entry.file.filePath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      continue;
    }

    var currentPath = '';
    var cursor = roots;
    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      currentPath = currentPath.isEmpty ? segment : '$currentPath/$segment';
      final isLeaf = index == segments.length - 1;
      if (isLeaf) {
        cursor[currentPath] = _RepositoryTreeNode.file(
          id: currentPath,
          name: segment,
          entry: entry,
        );
      } else {
        final directory = cursor.putIfAbsent(
          currentPath,
          () => _RepositoryTreeNode.directory(id: currentPath, name: segment),
        );
        cursor = directory.children;
      }
    }
  }
  return _sortRepositoryTreeNodes(roots.values);
}

List<_RepositoryTreeNode> _sortRepositoryTreeNodes(
  Iterable<_RepositoryTreeNode> nodes,
) {
  final sorted = nodes.toList()
    ..sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  for (final node in sorted.where((node) => node.isDirectory)) {
    node.replaceChildren(_sortRepositoryTreeNodes(node.children.values));
  }
  return sorted;
}

void _toggleRepositoryFolder(
  _SessionGitRepositoryScreenState state,
  String folderId, {
  required bool expanded,
}) {
  state._updateView(() {
    if (expanded) {
      state._expandedFolderIds.remove(folderId);
    } else {
      state._expandedFolderIds.add(folderId);
    }
  });
}
