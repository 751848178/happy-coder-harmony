import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/session_project_repository_service.dart';
import '../domain/session_git_models.dart';
import 'session_git_diff_screen.dart';

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

  Future<void> _loadFiles() async {
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
        _error = '加载会话文件失败: $error';
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
            const Text('会话文件'),
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
            tooltip: '查看完整仓库',
            onPressed: () => context.push(
              AppRoutes.sessionGitDetail(widget.sessionId),
            ),
            icon: const Icon(Icons.account_tree_outlined),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: _loadFiles,
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.neutral700,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    if (data == null) {
      return const SizedBox.shrink();
    }

    final entries = _visibleEntries(data);
    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSummaryCard(data),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 12),
          if (!data.usedRpc || data.repository.fromDerivedData)
            _buildSourceBanner(data.repository.sourceLabel),
          if (!data.usedRpc || data.repository.fromDerivedData)
            const SizedBox(height: 12),
          if (entries.isEmpty)
            _buildEmptyState()
          else
            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChangedFileTile(
                  entry: entry,
                  onTap: () => _openEntry(entry),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SessionProjectRepositoryData data) {
    final uniqueChangedCount = {
      ...data.repository.stagedFiles.map((file) => file.path),
      ...data.repository.unstagedFiles.map((file) => file.path),
    }.length;

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
          const Text(
            '当前会话改动文件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.repository.rootPath.isEmpty
                ? '当前会话没有返回工作区路径'
                : data.repository.rootPath,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: '$uniqueChangedCount 个改动文件',
                color: AppTheme.brandColor,
              ),
              _SummaryChip(
                label: '已暂存 ${data.repository.stagedFiles.length}',
                color: AppTheme.successColor,
              ),
              _SummaryChip(
                label: '未暂存 ${data.repository.unstagedFiles.length}',
                color: AppTheme.warningColor,
              ),
              _SummaryChip(
                label:
                    '+${data.repository.totalAddedLines} / -${data.repository.totalRemovedLines}',
                color: AppTheme.infoColor,
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
        hintText: '搜索改动文件名或路径',
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
        '$sourceLabel。当前会话文件页会优先展示真实 Git 改动；只有在仓库 RPC 不可用时才回退到会话消息推断。',
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            Icons.task_alt_outlined,
            size: 48,
            color: AppTheme.neutral500,
          ),
          const SizedBox(height: 12),
          const Text(
            '当前没有检测到改动文件',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '如果你想查看整个仓库文件列表，可以进入 Git 仓库页面继续浏览。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push(
              AppRoutes.sessionGitDetail(widget.sessionId),
            ),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('打开 Git 仓库'),
          ),
        ],
      ),
    );
  }

  List<_ChangedFileEntry> _visibleEntries(SessionProjectRepositoryData data) {
    final query = _searchController.text.trim().toLowerCase();
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

    final entries = entriesByPath.values.where((entry) {
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

    return entries;
  }

  Future<void> _openEntry(_ChangedFileEntry entry) async {
    final file = entry.primaryChange;
    if (file == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionGitDiffScreen(
          sessionId: widget.sessionId,
          file: file,
        ),
      ),
    );
  }
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

class _ChangedFileTile extends StatelessWidget {
  const _ChangedFileTile({
    required this.entry,
    required this.onTap,
  });

  final _ChangedFileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = entry.primaryChange;
    if (primary == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusColor(primary.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForFile(primary.fileName),
                  color: _statusColor(primary.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      primary.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (entry.staged != null)
                          _StatusPill(
                            label:
                                '已暂存 · ${_statusLabel(entry.staged!.status)}',
                            color: _statusColor(entry.staged!.status),
                          ),
                        if (entry.unstaged != null)
                          _StatusPill(
                            label:
                                '未暂存 · ${_statusLabel(entry.unstaged!.status)}',
                            color: _statusColor(entry.unstaged!.status),
                          ),
                        if (entry.totalAdded > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.successColor,
                            valuePrefix: '+',
                          ).withValue(entry.totalAdded),
                        if (entry.totalRemoved > 0)
                          const _StatusPill(
                            label: '',
                            color: AppTheme.errorColor,
                            valuePrefix: '-',
                          ).withValue(entry.totalRemoved),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.code_outlined,
                color: AppTheme.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
