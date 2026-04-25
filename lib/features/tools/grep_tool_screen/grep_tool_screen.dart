import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

part 'feedback_widgets.dart';
part 'models.dart';
part 'notifier.dart';
part 'results.dart';
part 'search_input.dart';

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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('普通搜索', style: TextStyle(fontWeight: FontWeight.bold)),
              _HelpItem(pattern: 'MyApp', description: '搜索包含 "MyApp" 的行'),
              Divider(),
              Text('正则表达式搜索', style: TextStyle(fontWeight: FontWeight.bold)),
              _HelpItem(pattern: 'class \\w+', description: '匹配 class 关键字后跟单词'),
              _HelpItem(pattern: 'func.*\\(.*\\)', description: '匹配函数定义'),
              _HelpItem(pattern: '\\d{3,}', description: '匹配3个以上数字'),
              Divider(),
              Text('搜索选项', style: TextStyle(fontWeight: FontWeight.bold)),
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
