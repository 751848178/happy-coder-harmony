import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Grep Match Result
class GrepMatch {
  final String filePath;
  final int lineNumber;
  final String lineContent;
  final int? startColumn;
  final int? endColumn;

  const GrepMatch({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    this.startColumn,
    this.endColumn,
  });
}

/// Grep State
class GrepState {
  final bool isSearching;
  final List<GrepMatch> matches;
  final String? error;
  final String currentPattern;
  final String currentPath;
  final bool caseSensitive;
  final bool useRegex;
  final int maxResults;

  const GrepState({
    this.isSearching = false,
    this.matches = const [],
    this.error,
    this.currentPattern = '',
    this.currentPath = '.',
    this.caseSensitive = false,
    this.useRegex = false,
    this.maxResults = 100,
  });

  GrepState copyWith({
    bool? isSearching,
    List<GrepMatch>? matches,
    String? error,
    String? currentPattern,
    String? currentPath,
    bool? caseSensitive,
    bool? useRegex,
    int? maxResults,
  }) {
    return GrepState(
      isSearching: isSearching ?? this.isSearching,
      matches: matches ?? this.matches,
      error: error ?? this.error,
      currentPattern: currentPattern ?? this.currentPattern,
      currentPath: currentPath ?? this.currentPath,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      useRegex: useRegex ?? this.useRegex,
      maxResults: maxResults ?? this.maxResults,
    );
  }
}

/// Grep Tool Notifier
class GrepNotifier extends StateNotifier<GrepState> {
  GrepNotifier() : super(const GrepState());

  Future<void> search(
    String pattern,
    String path, {
    bool caseSensitive = false,
    bool useRegex = false,
    int maxResults = 100,
  }) async {
    state = state.copyWith(
      isSearching: true,
      error: null,
      currentPattern: pattern,
      currentPath: path,
      caseSensitive: caseSensitive,
      useRegex: useRegex,
      maxResults: maxResults,
    );

    try {
      // TODO: Call API to perform grep search
      // final results = await _api.grep(
      //   pattern: pattern,
      //   path: path,
      //   caseSensitive: caseSensitive,
      //   useRegex: useRegex,
      //   maxResults: maxResults,
      // );
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock results for demo
      final mockResults = <GrepMatch>[
        GrepMatch(
          filePath: '$path/lib/main.dart',
          lineNumber: 10,
          lineContent: 'void main() {',
        ),
        GrepMatch(
          filePath: '$path/lib/main.dart',
          lineNumber: 12,
          lineContent: '  runApp(const MyApp());',
        ),
        GrepMatch(
          filePath: '$path/lib/app.dart',
          lineNumber: 15,
          lineContent: 'class MyApp extends StatelessWidget {',
        ),
        GrepMatch(
          filePath: '$path/features/chat/chat_screen.dart',
          lineNumber: 23,
          lineContent: 'class ChatScreen extends ConsumerWidget {',
        ),
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
    state = const GrepState();
  }
}

/// Grep Tool Screen
///
/// 文件内容搜索工具
class GrepToolScreen extends ConsumerStatefulWidget {
  const GrepToolScreen({super.key});

  @override
  ConsumerState<GrepToolScreen> createState() => _GrepToolScreenState();
}

class _GrepToolScreenState extends ConsumerState<GrepToolScreen> {
  final _patternController = TextEditingController();
  final _pathController = TextEditingController(text: '.');
  final _scrollController = ScrollController();

  bool _caseSensitive = false;
  bool _useRegex = false;

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
        title: const Text('Grep 内容搜索'),
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
            caseSensitive: _caseSensitive,
            useRegex: _useRegex,
            onCaseSensitiveChanged: (value) {
              setState(() => _caseSensitive = value);
            },
            onUseRegexChanged: (value) {
              setState(() => _useRegex = value);
            },
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
        const SnackBar(content: Text('请输入搜索内容')),
      );
      return;
    }

    ref.read(grepNotifierProvider.notifier).search(
      pattern,
      path,
      caseSensitive: _caseSensitive,
      useRegex: _useRegex,
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grep 搜索帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '普通搜索',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _HelpItem(pattern: 'MyApp', description: '搜索包含 "MyApp" 的行'),
              Divider(),
              Text(
                '正则表达式搜索',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _HelpItem(pattern: 'class \\w+', description: '匹配 class 关键字后跟单词'),
              _HelpItem(pattern: 'func.*\\(.*\\)', description: '匹配函数定义'),
              _HelpItem(pattern: '\\d{3,}', description: '匹配3个以上数字'),
              Divider(),
              Text(
                '搜索选项',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _HelpItem(pattern: '区分大小写', description: '精确匹配大小写'),
              _HelpItem(pattern: '使用正则', description: '启用正则表达式模式'),
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
  final bool caseSensitive;
  final bool useRegex;
  final ValueChanged<bool> onCaseSensitiveChanged;
  final ValueChanged<bool> onUseRegexChanged;
  final VoidCallback onSearch;

  const _SearchInput({
    required this.patternController,
    required this.pathController,
    required this.caseSensitive,
    required this.useRegex,
    required this.onCaseSensitiveChanged,
    required this.onUseRegexChanged,
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
              labelText: useRegex ? '正则表达式' : '搜索内容',
              hintText: useRegex ? '例如: class \\w+' : '例如: MyApp',
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
          TextField(
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
          const SizedBox(height: 12),
          // Options Row
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('区分大小写'),
                selected: caseSensitive,
                onSelected: onCaseSensitiveChanged,
                avatar: Icon(
                  Icons.text_fields,
                  size: 16,
                  color: caseSensitive ? Colors.white : null,
                ),
                selectedColor: AppTheme.brandColor,
              ),
              FilterChip(
                label: const Text('使用正则'),
                selected: useRegex,
                onSelected: onUseRegexChanged,
                avatar: Icon(
                  Icons.code,
                  size: 16,
                  color: useRegex ? Colors.white : null,
                ),
                selectedColor: AppTheme.brandColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('搜索'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
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
    final state = ref.watch(grepNotifierProvider);

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
        onRetry: () => ref.read(grepNotifierProvider.notifier).search(
          state.currentPattern,
          state.currentPath,
          caseSensitive: state.caseSensitive,
          useRegex: state.useRegex,
        ),
      );
    }

    if (state.matches.isEmpty && state.currentPattern.isEmpty) {
      return _EmptyView(
        onSampleSearch: () {
          ref.read(grepNotifierProvider.notifier).search('MyApp', '.');
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
                '找到 ${state.matches.length} 个匹配',
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
                  backgroundColor: AppTheme.brandColor.withOpacity(0.1),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    ref.read(grepNotifierProvider.notifier).clear();
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
  final GrepMatch match;

  const _MatchItem({required this.match});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${match.filePath}:${match.lineNumber}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.neutral200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File path and line number
            Row(
              children: [
                Icon(Icons.description, size: 16, color: AppTheme.neutral500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.filePath,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '行 ${match.lineNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Line content
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${match.lineNumber}:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.lineContent,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              '文件内容搜索',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入关键词或正则表达式搜索文件内容',
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
            '搜索: $pattern',
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

/// Grep Provider
final grepNotifierProvider =
    StateNotifierProvider<GrepNotifier, GrepState>((ref) {
      return GrepNotifier();
    });
