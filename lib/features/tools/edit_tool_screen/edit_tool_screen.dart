import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';

part 'content.dart';

class EditToolScreen extends ConsumerStatefulWidget {
  const EditToolScreen({super.key});

  @override
  ConsumerState<EditToolScreen> createState() => _EditToolScreenState();
}

class _EditToolScreenState extends ConsumerState<EditToolScreen> {
  final _codeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;
  String _selectedLanguage = 'dart';

  @override
  void dispose() {
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback update) {
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('编辑器'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: '编辑',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
              tooltip: '完成',
            ),
            TextButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.content_copy),
              label: const Text('复制'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.brandColor),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已刷新'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              tooltip: '刷新',
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _codeController.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已清空'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
                return;
              }
              if (value == 'copy') {
                _copyToClipboard();
                return;
              }
              _updateState(() => _selectedLanguage = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'dart', child: Text('Dart')),
              PopupMenuItem(value: 'python', child: Text('Python')),
              PopupMenuItem(value: 'javascript', child: Text('JavaScript')),
              PopupMenuItem(value: 'copy', child: Text('复制')),
              PopupMenuItem(value: 'clear', child: Text('清空')),
            ],
          ),
        ],
      ),
      body: _isEditing ? _buildEditor() : _buildReadOnlyView(),
    );
  }

  void _copyToClipboard() {
    final code = _codeController.text;
    if (code.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: $code'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
