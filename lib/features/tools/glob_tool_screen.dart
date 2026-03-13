import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Glob Pattern Match Result
class GlobMatch {
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;

  const GlobMatch({
    required this.path,
    this.isDirectory = false,
    this.size,
    this.modifiedAt,
  });
}

/// Glob Tool State
class GlobState {
  final bool isSearching;
  final List<GlobMatch> matches;
  final String? error;
  final String currentPattern;
  final String currentPath;

  const GlobState({
    this.isSearching = false,
    this.matches = const [],
    this.error,
    this.currentPattern = '',
    this.currentPath = '.',
  });

  GlobState copyWith({
    bool? isSearching,
    List<GlobMatch>? matches,
    String? error,
    String? currentPattern,
    String? currentPath,
  }) {
    return GlobState(
      isSearching: isSearching ?? this.isSearching,
      matches: matches ?? this.matches,
      error: error ?? this.error,
      currentPattern: currentPattern ?? this.currentPattern,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}

/// Glob Tool Notifier
class GlobNotifier extends StateNotifier<GlobState> {
  GlobNotifier() : super(const GlobState());

  Future<void> search(String pattern, String path) async {
    state = state.copyWith(
      isSearching: true,
      error: null,
      currentPattern: pattern,
      currentPath: path,
    );

    try {
      // TODO: Call API to perform glob search
      // final results = await _api.glob(pattern: pattern, path: path);
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

      // Mock results for demo
      final mockResults = <GlobMatch>[
        GlobMatch(path: '$path/lib/main.dart', size: 1234, modifiedAt: DateTime.now()),
        GlobMatch(path: '$path/lib/app.dart', size: 567, modifiedAt: DateTime.now()),
        GlobMatch(path: '$path/lib/features', isDirectory: true),
        GlobMatch(path: '$path/lib/core', isDirectory: true),
        GlobMatch(path: '$path/test', isDirectory: true),
        GlobMatch(path: '$path/pubspec.yaml', size: 234, modifiedAt: DateTime.now()),
      ];

      state = state.copyWith(
        isSearching: false,
        matches: mockResults,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
        matches: [],
      );
    }
  }

  void clear() {
    state = const GlobState();
  }
}

/// Glob Tool Screen
///
/// 文件模式匹配工具
class GlobToolScreen extends ConsumerStatefulWidget {
  const GlobToolScreen({super.key});

  @override
  ConsumerState<GlobToolScreen> createState() => _GlobToolScreenState();
}

class _GlobToolScreenState extends ConsumerState<GlobToolScreen> {
  final _patternController = TextEditingController();
  final _pathController = TextEditingController(text: '.');
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _patternController.dispose();
    _pathController.dispose();
    _scrollController.dispose();
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
        title: const Text('Glob 模式匹配'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '帮助',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Section
          _SearchInput(
            patternController: _patternController,
            pathController: _pathController,
            onSearch: _performSearch,
          ),
          // Results Section
          Expanded(
            child: _ResultsList(scrollController: _scrollController),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final pattern = _patternController.text.trim();
    final path = _pathController.text.trim().isEmpty ? '.' : _pathController.text.trim();

    if (pattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入匹配模式')),
      );
      return;
    }

    ref.read(globNotifierProvider.notifier).search(pattern, path);
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Glob 模式帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpItem(pattern: '*.dart', description: '匹配所有 .dart 文件'),
              _HelpItem(pattern: '**/*.dart', description: '递归匹配所有 .dart 文件'),
              _HelpItem(pattern: 'lib/**/*.dart', description: '匹配 lib 目录下所有 .dart 文件'),
              _HelpItem(pattern: 'test/test_*.dart', description: '匹配 test 目录下以 test_ 开头的文件'),
              _HelpItem(pattern: '**/*_test.dart', description: '匹配所有以 _test.dart 结尾的文件'),
              _HelpItem(pattern: '[a-c]*', description: '匹配以 a, b, c 开头的文件'),
              _HelpItem(pattern: '?.dart', description: '匹配单字符的 .dart 文件'),
              _HelpItem(pattern: '{src,lib}', description: '匹配 src 或 lib 目录'),
              Divider(),
              Text(
                '特殊字符:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _HelpItem(pattern: '*', description: '匹配任意字符（除 /）'),
              _HelpItem(pattern: '**', description: '匹配任意字符（包括 /）'),
              _HelpItem(pattern: '?', description: '匹配单个字符'),
            ],
          ),
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
}

/// Search Input Section
class _SearchInput extends StatelessWidget {
  final TextEditingController patternController;
  final TextEditingController pathController;
  final VoidCallback onSearch;

  const _SearchInput({
    required this.patternController,
    required this.pathController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern Input
          TextField(
            controller: patternController,
            decoration: InputDecoration(
              labelText: '匹配模式',
              hintText: '例如: **/*.dart',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => patternController.clear(),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 12),
          // Path Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: '搜索路径',
                    hintText: '默认: . (当前目录)',
                    prefixIcon: const Icon(Icons.folder),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('搜索'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          // Common Patterns
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PatternChip(
                label: '*.dart',
                onTap: () {
                  patternController.text = '*.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: '**/*.dart',
                onTap: () {
                  patternController.text = '**/*.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: '**/*_test.dart',
                onTap: () {
                  patternController.text = '**/*_test.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: 'pubspec.yaml',
                onTap: () {
                  patternController.text = 'pubspec.yaml';
                  onSearch();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pattern Chip
class _PatternChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PatternChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.code, size: 16),
      onPressed: onTap,
      backgroundColor: AppTheme.neutral100,
      labelStyle: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 12,
      ),
    );
  }
}

/// Results List
class _ResultsList extends ConsumerWidget {
  final ScrollController scrollController;

  const _ResultsList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(globNotifierProvider);

    if (state.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.brandColor),
            SizedBox(height: 16),
            Text(
              '搜索中...',
              style: TextStyle(color: AppTheme.neutral600),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        errorMessage: state.error!,
        onRetry: () => ref.read(globNotifierProvider.notifier).search(
          state.currentPattern,
          state.currentPath,
        ),
      );
    }

    if (state.matches.isEmpty && state.currentPattern.isEmpty) {
      return _EmptyView(
        onSampleSearch: () {
          ref.read(globNotifierProvider.notifier).search('**/*.dart', '.');
        },
      );
    }

    if (state.matches.isEmpty) {
      return _NoResultsView(pattern: state.currentPattern);
    }

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.neutral100,
          child: Row(
            children: [
              Text(
                '找到 ${state.matches.length} 个匹配项',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (state.currentPattern.isNotEmpty)
                Chip(
                  label: Text(
                    state.currentPattern,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    ref.read(globNotifierProvider.notifier).clear();
                  },
                ),
            ],
          ),
        ),
        // Results List
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: state.matches.length,
            itemBuilder: (context, index) {
              final match = state.matches[index];
              return _MatchItem(match: match);
            },
          ),
        ),
      ],
    );
  }
}

/// Match Item
class _MatchItem extends StatelessWidget {
  final GlobMatch match;

  const _MatchItem({required this.match});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选中: ${match.path}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.neutral200),
          ),
        ),
        child: Row(
          children: [
            _getFileIcon(match.isDirectory),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.path,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: match.isDirectory ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (!match.isDirectory && match.size != null)
                    Text(
                      _formatSize(match.size!),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutral500,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.neutral400),
          ],
        ),
      ),
    );
  }

  Icon _getFileIcon(bool isDirectory) {
    return Icon(
      isDirectory ? Icons.folder : Icons.insert_drive_file,
      color: isDirectory ? AppTheme.brandColor : AppTheme.neutral500,
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Empty View
class _EmptyView extends StatelessWidget {
  final VoidCallback onSampleSearch;

  const _EmptyView({required this.onSampleSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              '文件模式匹配',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入 Glob 模式来查找文件',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onSampleSearch,
              icon: const Icon(Icons.play_arrow),
              label: const Text('尝试示例搜索'),
            ),
          ],
        ),
      ),
    );
  }
}

/// No Results View
class _NoResultsView extends StatelessWidget {
  final String pattern;

  const _NoResultsView({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '未找到匹配项',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '模式: $pattern',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral500,
            ),
          ),
        ],
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
              '搜索失败',
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

/// Help Item
class _HelpItem extends StatelessWidget {
  final String pattern;
  final String description;

  const _HelpItem({required this.pattern, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pattern,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glob Provider
final globNotifierProvider =
    StateNotifierProvider<GlobNotifier, GlobState>((ref) {
  return GlobNotifier();
});
