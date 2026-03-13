import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Directory Entry
class DirectoryEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;
  final String? permissions;

  const DirectoryEntry({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size,
    this.modifiedAt,
    this.permissions,
  });
}

/// LS State
class LsState {
  final bool isLoading;
  final List<DirectoryEntry> entries;
  final String? error;
  final String currentPath;
  final List<String> pathHistory;
  final SortField sortField;
  final SortOrder sortOrder;

  const LsState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
    this.currentPath = '.',
    this.pathHistory = const [],
    this.sortField = SortField.name,
    this.sortOrder = SortOrder.ascending,
  });

  LsState copyWith({
    bool? isLoading,
    List<DirectoryEntry>? entries,
    String? error,
    String? currentPath,
    List<String>? pathHistory,
    SortField? sortField,
    SortOrder? sortOrder,
  }) {
    return LsState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      error: error ?? this.error,
      currentPath: currentPath ?? this.currentPath,
      pathHistory: pathHistory ?? this.pathHistory,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum SortField { name, size, modified }
enum SortOrder { ascending, descending }

/// LS Tool Notifier
class LsNotifier extends StateNotifier<LsState> {
  LsNotifier() : super(const LsState());

  Future<void> listDirectory(String path) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      // TODO: Call API to list directory
      // final result = await _api.ls(path: path);
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock results for demo
      final mockEntries = <DirectoryEntry>[
        DirectoryEntry(
          name: 'lib',
          path: './lib',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 1),
        ),
        DirectoryEntry(
          name: 'features',
          path: './features',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 2),
        ),
        DirectoryEntry(
          name: 'test',
          path: './test',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 1),
        ),
        DirectoryEntry(
          name: 'pubspec.yaml',
          path: './pubspec.yaml',
          isDirectory: false,
          size: 1234,
          modifiedAt: DateTime(2026, 2, 28),
          permissions: 'rw-r--r--',
        ),
        DirectoryEntry(
          name: 'README.md',
          path: './README.md',
          isDirectory: false,
          size: 5678,
          modifiedAt: DateTime(2026, 2, 25),
          permissions: 'rw-r--r--',
        ),
        DirectoryEntry(
          name: '.gitignore',
          path: './.gitignore',
          isDirectory: false,
          size: 234,
          modifiedAt: DateTime(2026, 2, 20),
          permissions: 'rw-------',
        ),
      ];

      final newHistory = path != state.currentPath
          ? [...state.pathHistory, state.currentPath]
          : state.pathHistory;

      state = state.copyWith(
        isLoading: false,
        entries: mockEntries,
        currentPath: path,
        pathHistory: newHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        entries: [],
      );
    }
  }

  void navigateUp() {
    if (state.pathHistory.isNotEmpty) {
      final newPath = state.pathHistory.removeLast();
      listDirectory(newPath);
      state = state.copyWith(pathHistory: state.pathHistory);
    } else if (state.currentPath != '.' && state.currentPath.isNotEmpty) {
      final parts = state.currentPath.split('/');
      parts.removeLast();
      final newPath = parts.isEmpty ? '.' : parts.join('/');
      listDirectory(newPath);
    }
  }

  void setSort(SortField field) {
    final newOrder = field == state.sortField && state.sortOrder == SortOrder.ascending
        ? SortOrder.descending
        : SortOrder.ascending;

    final sorted = List<DirectoryEntry>.from(state.entries);
    sorted.sort((a, b) {
      int compare;
      switch (field) {
        case SortField.name:
          compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortField.size:
          final sizeA = a.size ?? 0;
          final sizeB = b.size ?? 0;
          compare = sizeA.compareTo(sizeB);
          break;
        case SortField.modified:
          final dateA = a.modifiedAt ?? DateTime(0);
          final dateB = b.modifiedAt ?? DateTime(0);
          compare = dateA.compareTo(dateB);
          break;
      }
      return newOrder == SortOrder.ascending ? compare : -compare;
    });

    state = state.copyWith(
      entries: sorted,
      sortField: field,
      sortOrder: newOrder,
    );
  }

  void refresh() {
    listDirectory(state.currentPath);
  }
}

/// LS Tool Screen
///
/// 目录列表工具
class LsToolScreen extends ConsumerStatefulWidget {
  const LsToolScreen({super.key});

  @override
  ConsumerState<LsToolScreen> createState() => _LsToolScreenState();
}

class _LsToolScreenState extends ConsumerState<LsToolScreen> {
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial directory
    Future.microtask(() {
      ref.read(lsNotifierProvider.notifier).listDirectory('.');
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('目录浏览'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(lsNotifierProvider.notifier).refresh(),
            tooltip: '刷新',
          ),
          PopupMenuButton<SortField>(
            onSelected: (field) {
              ref.read(lsNotifierProvider.notifier).setSort(field);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortField.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 18),
                    SizedBox(width: 12),
                    Text('按名称排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortField.size,
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 18),
                    SizedBox(width: 12),
                    Text('按大小排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortField.modified,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 12),
                    Text('按修改时间排序'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Path Bar
          _PathBar(controller: _pathController),
          // Entries List
          Expanded(
            child: _EntriesList(),
          ),
        ],
      ),
    );
  }
}

/// Path Bar
class _PathBar extends ConsumerWidget {
  final TextEditingController controller;

  const _PathBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lsNotifierProvider);
    controller.text = state.currentPath;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: state.pathHistory.isEmpty && state.currentPath == '.'
                ? null
                : () => ref.read(lsNotifierProvider.notifier).navigateUp(),
            tooltip: '上级目录',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '当前路径',
                hintText: '.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (value) {
                ref.read(lsNotifierProvider.notifier).listDirectory(
                  value.trim().isEmpty ? '.' : value.trim(),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              ref.read(lsNotifierProvider.notifier).listDirectory(controller.text);
            },
            tooltip: '前往',
          ),
        ],
      ),
    );
  }
}

/// Entries List
class _EntriesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lsNotifierProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        errorMessage: state.error!,
        onRetry: () => ref.read(lsNotifierProvider.notifier).refresh(),
      );
    }

    if (state.entries.isEmpty) {
      return _EmptyView(
        path: state.currentPath,
        onRetry: () => ref.read(lsNotifierProvider.notifier).refresh(),
      );
    }

    return Column(
      children: [
        // Stats Bar
        _StatsBar(
          totalEntries: state.entries.length,
          directories: state.entries.where((e) => e.isDirectory).length,
          files: state.entries.where((e) => !e.isDirectory).length,
        ),
        // Entries Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.5 : 1.2,
                ),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  return _EntryCard(entry: entry);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Entry Card
class _EntryCard extends ConsumerWidget {
  final DirectoryEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (entry.isDirectory) {
          ref.read(lsNotifierProvider.notifier).listDirectory(entry.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开文件: ${entry.name}')),
          );
        }
      },
      onLongPress: () {
        _showEntryMenu(context, entry);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Name
            Row(
              children: [
                Icon(
                  entry.isDirectory ? Icons.folder : _getFileIcon(entry.name),
                  color: entry.isDirectory ? AppTheme.brandColor : AppTheme.neutral500,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: entry.isDirectory ? FontWeight.w600 : FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Size and Date
            if (!entry.isDirectory && entry.size != null)
              Text(
                _formatSize(entry.size!),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.neutral500,
                ),
              ),
            if (entry.modifiedAt != null)
              Text(
                _formatDate(entry.modifiedAt!),
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.neutral400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _showEntryMenu(BuildContext context, DirectoryEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  entry.isDirectory ? Icons.folder : _getFileIcon(entry.name),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.isDirectory ? '目录' : '文件',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.open_in_new,
              label: '打开',
              onTap: () {
                Navigator.pop(context);
                if (entry.isDirectory) {
                  // TODO: Navigate to directory
                } else {
                  // TODO: Open file
                }
              },
            ),
            if (!entry.isDirectory) ...[
              _MenuItem(
                icon: Icons.file_download,
                label: '下载',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('下载功能开发中')),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.copy,
                label: '复制路径',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已复制: ${entry.path}')),
                  );
                },
              ),
            ],
            _MenuItem(
              icon: Icons.info_outline,
              label: '详细信息',
              onTap: () {
                Navigator.pop(context);
                _showEntryDetails(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, DirectoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('路径', entry.path),
            _DetailRow('类型', entry.isDirectory ? '目录' : '文件'),
            if (!entry.isDirectory && entry.size != null)
              _DetailRow('大小', _formatSize(entry.size!)),
            if (entry.modifiedAt != null)
              _DetailRow('修改时间', _formatDate(entry.modifiedAt!)),
            if (entry.permissions != null)
              _DetailRow('权限', entry.permissions!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'py':
        return Icons.data_object;
      case 'json':
      case 'yaml':
      case 'yml':
        return Icons.description;
      case 'md':
        return Icons.article;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// Stats Bar
class _StatsBar extends StatelessWidget {
  final int totalEntries;
  final int directories;
  final int files;

  const _StatsBar({
    required this.totalEntries,
    required this.directories,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.neutral100,
      child: Row(
        children: [
          _StatItem(label: '总计', value: totalEntries.toString()),
          const SizedBox(width: 16),
          _StatItem(
            label: '目录',
            value: directories.toString(),
            color: AppTheme.brandColor,
          ),
          const SizedBox(width: 16),
          _StatItem(
            label: '文件',
            value: files.toString(),
            color: AppTheme.neutral600,
          ),
        ],
      ),
    );
  }
}

/// Stat Item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Menu Item
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

/// Detail Row
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty View
class _EmptyView extends StatelessWidget {
  final String path;
  final VoidCallback onRetry;

  const _EmptyView({
    required this.path,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              '目录为空',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error View
class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// LS Provider
final lsNotifierProvider =
    StateNotifierProvider<LsNotifier, LsState>((ref) {
      return LsNotifier();
    });
