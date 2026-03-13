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

enum _RepositoryFilter {
  all,
  changed,
  staged,
  unstaged,
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

  Future<void> _loadRepository() async {
    setState(() {
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

      setState(() {
        _session = session;
        _data = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '加载 Git 仓库失败: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Git 仓库'),
            if (_session != null)
              Text(
                _session!.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '查看改动文件',
            onPressed: () => context.push(
              AppRoutes.sessionFilesDetail(widget.sessionId),
            ),
            icon: const Icon(Icons.compare_arrows_outlined),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: _loadRepository,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(data),
    );
  }

  Widget _buildBody(SessionProjectRepositoryData? data) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(
              color: AppTheme.neutral700,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final visibleFiles = _visibleFiles(data);
    final treeNodes = _buildTreeNodes(visibleFiles);
    final forceExpandAll = _searchController.text.trim().isNotEmpty;
    return RefreshIndicator(
      onRefresh: _loadRepository,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSummaryCard(data),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildFilterBar(data.repository),
          const SizedBox(height: 12),
          if (!data.usedRpc || data.repository.fromDerivedData)
            _buildSourceBanner(data.repository.sourceLabel),
          if (!data.usedRpc || data.repository.fromDerivedData)
            const SizedBox(height: 12),
          if (visibleFiles.isEmpty)
            _buildEmptyState(data)
          else
            ..._buildRepositoryTree(
              treeNodes,
              depth: 0,
              forceExpandAll: forceExpandAll,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SessionProjectRepositoryData data) {
    final repository = data.repository;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: AppTheme.brandColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repository.branch,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      repository.rootPath.isEmpty
                          ? '当前会话未返回工作区路径'
                          : repository.rootPath,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: '${data.projectFiles.length} 个仓库文件',
                color: AppTheme.infoColor,
              ),
              _SummaryChip(
                label: '${repository.totalChangedFiles} 个改动文件',
                color: AppTheme.brandColor,
              ),
              _SummaryChip(
                label: '+${repository.totalAddedLines} 行',
                color: AppTheme.successColor,
              ),
              _SummaryChip(
                label: '-${repository.totalRemovedLines} 行',
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: '搜索仓库文件',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterBar(SessionGitRepositoryView repository) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: '全部',
          selected: _filter == _RepositoryFilter.all,
          onTap: () => setState(() => _filter = _RepositoryFilter.all),
        ),
        _FilterChipButton(
          label: '仅改动',
          selected: _filter == _RepositoryFilter.changed,
          onTap: () => setState(() => _filter = _RepositoryFilter.changed),
        ),
        _FilterChipButton(
          label: '已暂存 ${repository.stagedFiles.length}',
          selected: _filter == _RepositoryFilter.staged,
          onTap: () => setState(() => _filter = _RepositoryFilter.staged),
        ),
        _FilterChipButton(
          label: '未暂存 ${repository.unstagedFiles.length}',
          selected: _filter == _RepositoryFilter.unstaged,
          onTap: () => setState(() => _filter = _RepositoryFilter.unstaged),
        ),
      ],
    );
  }

  Widget _buildSourceBanner(String sourceLabel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '$sourceLabel。当前仍会优先使用真实仓库 RPC；只有在 RPC 不可用时才回退到会话消息推断。',
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(SessionProjectRepositoryData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppTheme.neutral500,
          ),
          const SizedBox(height: 12),
          const Text(
            '当前筛选条件下没有文件',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.projectFiles.isEmpty ? '当前没有拿到仓库文件列表。' : '换个关键词，或者切换筛选项继续查看。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  List<_ProjectFileEntry> _visibleFiles(SessionProjectRepositoryData data) {
    final query = _searchController.text.trim().toLowerCase();
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
        file.path,
        () => _ProjectFileEntry.fromGitFile(file),
      );
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
      switch (_filter) {
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

    if (_filter == _RepositoryFilter.changed &&
        filtered.isEmpty &&
        query.isEmpty) {
      return [
        ...data.repository.stagedFiles.map(_ProjectFileEntry.fromGitFile),
        ...data.repository.unstagedFiles.map(_ProjectFileEntry.fromGitFile),
      ];
    }

    return filtered;
  }

  Future<void> _openFile(_ProjectFileEntry entry) async {
    final changedFile = entry.primaryChange;
    if (changedFile != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionGitDiffScreen(
            sessionId: widget.sessionId,
            file: changedFile,
          ),
        ),
      );
      return;
    }

    final uri = Uri(
      path: AppRoutes.sessionFileDetail(widget.sessionId),
      queryParameters: {
        'fileId': entry.file.id,
        'path': entry.file.filePath,
        'name': entry.file.fileName,
        if (entry.file.mimeType != null && entry.file.mimeType!.isNotEmpty)
          'mimeType': entry.file.mimeType!,
      },
    );
    await context.push(uri.toString());
  }

  List<Widget> _buildRepositoryTree(
    List<_RepositoryTreeNode> nodes, {
    required int depth,
    required bool forceExpandAll,
  }) {
    final widgets = <Widget>[];
    for (final node in nodes) {
      if (node.isDirectory) {
        final expanded =
            forceExpandAll || depth == 0 || _expandedFolderIds.contains(node.id);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RepositoryFolderTile(
              node: node,
              depth: depth,
              expanded: expanded,
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedFolderIds.remove(node.id);
                  } else {
                    _expandedFolderIds.add(node.id);
                  }
                });
              },
            ),
          ),
        );
        if (expanded) {
          widgets.addAll(
            _buildRepositoryTree(
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
            onTap: () => _openFile(entry),
          ),
        ),
      );
    }
    return widgets;
  }

  List<_RepositoryTreeNode> _buildTreeNodes(List<_ProjectFileEntry> entries) {
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
        currentPath =
            currentPath.isEmpty ? segment : '$currentPath/$segment';
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
            () => _RepositoryTreeNode.directory(
              id: currentPath,
              name: segment,
            ),
          );
          cursor = directory.children;
        }
      }
    }

    List<_RepositoryTreeNode> sortNodes(Iterable<_RepositoryTreeNode> nodes) {
      final sorted = nodes.toList()
        ..sort((a, b) {
          if (a.isDirectory != b.isDirectory) {
            return a.isDirectory ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      for (final node in sorted.where((node) => node.isDirectory)) {
        node.replaceChildren(sortNodes(node.children.values));
      }
      return sorted;
    }

    return sortNodes(roots.values);
  }
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
    final totalAdded = (staged?.addedLines ?? 0) + (unstaged?.addedLines ?? 0);
    final totalRemoved =
        (staged?.removedLines ?? 0) + (unstaged?.removedLines ?? 0);
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

class _RepositoryFolderTile extends StatelessWidget {
  const _RepositoryFolderTile({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.onTap,
  });

  final _RepositoryTreeNode node;
  final int depth;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: EdgeInsets.fromLTRB(14 + (depth * 18), 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.changedCount > 0
                          ? '${node.fileCount} 个文件 · ${node.changedCount} 个有改动'
                          : '${node.fileCount} 个文件',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (node.changedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${node.changedCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectTreeFileTile extends StatelessWidget {
  const _ProjectTreeFileTile({
    required this.entry,
    required this.depth,
    required this.onTap,
  });

  final _ProjectFileEntry entry;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = entry.file;
    final staged = entry.staged;
    final unstaged = entry.unstaged;
    final isChanged = entry.isChanged;
    final totalAdded = (staged?.addedLines ?? 0) + (unstaged?.addedLines ?? 0);
    final totalRemoved =
        (staged?.removedLines ?? 0) + (unstaged?.removedLines ?? 0);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: EdgeInsets.fromLTRB(22 + (depth * 18), 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isChanged
                  ? AppTheme.brandColor.withValues(alpha: 0.2)
                  : AppTheme.neutral200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isChanged ? AppTheme.brandColor : AppTheme.neutral400)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _ProjectFileTile._iconForFile(file.fileName),
                  color: isChanged ? AppTheme.brandColor : AppTheme.neutral700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (depth == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        file.filePath,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral600,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (staged != null)
                          _StatusPill(
                            label:
                                '已暂存 · ${_ProjectFileTile._statusLabel(staged.status)}',
                            color: _ProjectFileTile._statusColor(staged.status),
                          ),
                        if (unstaged != null)
                          _StatusPill(
                            label:
                                '未暂存 · ${_ProjectFileTile._statusLabel(unstaged.status)}',
                            color:
                                _ProjectFileTile._statusColor(unstaged.status),
                          ),
                        if (totalAdded > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.successColor,
                            valuePrefix: '+',
                          ).withValue(totalAdded),
                        if (totalRemoved > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.errorColor,
                            valuePrefix: '-',
                          ).withValue(totalRemoved),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isChanged ? Icons.code_outlined : Icons.chevron_right,
                color: AppTheme.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectFileTile {
  const _ProjectFileTile._();

  static IconData _iconForFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.dart') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.tsx') ||
        lower.endsWith('.jsx') ||
        lower.endsWith('.py') ||
        lower.endsWith('.go') ||
        lower.endsWith('.java') ||
        lower.endsWith('.kt') ||
        lower.endsWith('.swift') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml')) {
      return Icons.code_outlined;
    }
    if (lower.endsWith('.md')) {
      return Icons.notes_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static String _statusLabel(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return '新增';
      case SessionGitFileStatus.deleted:
        return '删除';
      case SessionGitFileStatus.renamed:
        return '重命名';
      case SessionGitFileStatus.untracked:
        return '未跟踪';
      case SessionGitFileStatus.modified:
        return '修改';
    }
  }

  static Color _statusColor(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return AppTheme.successColor;
      case SessionGitFileStatus.deleted:
        return AppTheme.errorColor;
      case SessionGitFileStatus.renamed:
        return AppTheme.infoColor;
      case SessionGitFileStatus.untracked:
        return AppTheme.neutral600;
      case SessionGitFileStatus.modified:
        return AppTheme.warningColor;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandColor.withValues(alpha: 0.14)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.brandColor : AppTheme.neutral200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.brandColor : AppTheme.neutral700,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.value,
    this.valuePrefix = '',
  });

  final String label;
  final Color color;
  final int? value;
  final String valuePrefix;

  _StatusPill withValue(int nextValue) {
    return _StatusPill(
      label: label,
      color: color,
      value: nextValue,
      valuePrefix: valuePrefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : label.isEmpty
            ? '$valuePrefix$value'
            : '$label $valuePrefix$value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
