import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

part 'glob_feedback_widgets.dart';
part 'glob_models.dart';
part 'glob_notifier.dart';
part 'glob_results.dart';
part 'glob_search_input.dart';

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
          _SearchInput(
            patternController: _patternController,
            pathController: _pathController,
            onSearch: _performSearch,
          ),
          Expanded(
            child: _ResultsList(scrollController: _scrollController),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final pattern = _patternController.text.trim();
    final path =
        _pathController.text.trim().isEmpty ? '.' : _pathController.text.trim();

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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(pattern: '*.dart', description: '匹配所有 .dart 文件'),
              _HelpItem(pattern: '**/*.dart', description: '递归匹配所有 .dart 文件'),
              _HelpItem(
                pattern: 'lib/**/*.dart',
                description: '匹配 lib 目录下所有 .dart 文件',
              ),
              _HelpItem(
                pattern: 'test/test_*.dart',
                description: '匹配 test 目录下以 test_ 开头的文件',
              ),
              _HelpItem(
                pattern: '**/*_test.dart',
                description: '匹配所有以 _test.dart 结尾的文件',
              ),
              _HelpItem(pattern: '[a-c]*', description: '匹配以 a, b, c 开头的文件'),
              _HelpItem(pattern: '?.dart', description: '匹配单字符的 .dart 文件'),
              _HelpItem(pattern: '{src,lib}', description: '匹配 src 或 lib 目录'),
              Divider(),
              Text('特殊字符:', style: TextStyle(fontWeight: FontWeight.bold)),
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
