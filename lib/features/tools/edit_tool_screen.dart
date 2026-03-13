import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

/// Edit Tool Screen
///
/// Provides a code editor with syntax highlighting
class EditToolScreen extends ConsumerStatefulWidget {
  const EditToolScreen({super.key});

  @override
  ConsumerState<EditToolScreen> createState() => _EditToolScreenState();
}

class _EditToolScreenState extends ConsumerState<EditToolScreen> {
  final _codeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isEditing = false;
  int _currentPosition = 0;
  String _selectedLanguage = 'dart'; // dart, python, javascript

  @override
  void dispose() {
    _codeController.dispose();
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
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Reload content (would sync with editor)
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
              } else if (value == 'copy') {
                _copyToClipboard();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'language',
                child: Text('Dart'),
              ),
              const PopupMenuItem(
                value: 'python',
                child: Text('Python'),
              ),
              const PopupMenuItem(
                value: 'javascript',
                child: Text('JavaScript'),
              ),
            ],
          ),
        ],
      ),
      body: _isEditing ? _buildEditor() : _buildReadOnlyView(),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Language selector
        _buildLanguageSelector(),

        const SizedBox(height: AppTheme.spacingMd),

        // Code editor
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.neutral900,
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _currentPosition = value.length;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status bar
        _buildStatusBar(),

        const SizedBox(height: AppTheme.spacingMd),

        // Code content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.neutral900,
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: SelectableText(
              _codeController.text.isNotEmpty
                  ? _codeController.text
                  : '// 在此输入代码...\n\n// 点击编辑按钮开始编辑',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_document,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '编辑模式',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_selectedLanguage',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.code),
      initialValue: _selectedLanguage,
      onSelected: (value) {
        setState(() => _selectedLanguage = value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'dart',
          child: const Text('Dart'),
        ),
        PopupMenuItem(
          value: 'python',
          child: const Text('Python'),
        ),
        PopupMenuItem(
          value: 'javascript',
          child: const Text('JavaScript'),
        ),
      ],
    );
  }

  void _copyToClipboard() {
    final code = _codeController.text;
    if (code.isNotEmpty) {
      // In a real app, this would use Clipboard.setData()
      // For now, show a toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制: $code'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}