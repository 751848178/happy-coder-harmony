import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

/// Write Tool Screen
///
/// Provides a file writing interface for creating and editing files
class WriteToolScreen extends ConsumerStatefulWidget {
  const WriteToolScreen({super.key});

  @override
  ConsumerState<WriteToolScreen> createState() => _WriteToolScreenState();
}

class _WriteToolScreenState extends ConsumerState<WriteToolScreen> {
  final _pathController = TextEditingController();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isWriting = false;
  bool _hasUnsavedChanges = false;
  bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _pathController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }

    if (_autoSaveEnabled) {
      _autoSave();
    }
  }

  Future<void> _autoSave() async {
    // Simulate auto-save (in real app, this would write to backend)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _writeFile() async {
    if (_isWriting) return;

    final path = _pathController.text.trim();
    final content = _contentController.text;

    if (path.isEmpty) {
      _showSnackBar('请输入文件路径', isError: true);
      return;
    }

    setState(() => _isWriting = true);

    try {
      // Simulate file write (in real app, this would call the backend API)
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        _showSnackBar('文件已写入: $path', isError: false);
        setState(() {
          _hasUnsavedChanges = false;
          _isWriting = false;
        });
      }
    } catch (e) {
      setState(() => _isWriting = false);
      if (mounted) {
        _showSnackBar('写入失败: $e', isError: true);
      }
    }
  }

  void _clearContent() {
    _showClearConfirmation();
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空内容'),
        content: const Text('确认要清空所有内容吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contentController.clear();
              setState(() => _hasUnsavedChanges = false);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _loadFromFile() {
    // In a real app, this would open a file picker
    if (mounted) {
      _showSnackBar('文件选择功能将在后续版本开放', isError: false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          title: const Text('文件写入'),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_outlined,
                      size: 14,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '未保存',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Switch(
              value: _autoSaveEnabled,
              onChanged: (value) => setState(() => _autoSaveEnabled = value),
              activeColor: AppTheme.brandColor,
            ),
            const SizedBox(width: 4),
            Text(
              '自动保存',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.file_open),
              onPressed: _loadFromFile,
              tooltip: '打开文件',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearContent,
              tooltip: '清空内容',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'new':
                    _pathController.clear();
                    _contentController.clear();
                    break;
                  case 'copy':
                    // In a real app, this would use Clipboard.setData()
                    _showSnackBar('内容已复制', isError: false);
                    break;
                  case 'stats':
                    _showStatsDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.file_present, size: 18),
                      SizedBox(width: 12),
                      Text('新建文件'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 18),
                      SizedBox(width: 12),
                      Text('复制内容'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, size: 18),
                      SizedBox(width: 12),
                      Text('统计信息'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _buildPathSection(),
            _buildEditorSection(),
            _buildStatusBar(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isWriting ? null : _writeFile,
          backgroundColor: _isWriting ? AppTheme.neutral300 : AppTheme.brandColor,
          foregroundColor: Colors.white,
          icon: _isWriting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isWriting ? '写入中...' : '写入文件'),
        ),
      ),
    );
  }

  Widget _buildPathSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: const BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            color: AppTheme.brandColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _pathController,
              decoration: InputDecoration(
                hintText: '输入文件路径 (例如: /path/to/file.txt)',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: AppTheme.neutral400,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          if (_pathController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(),
                    size: 14,
                    color: AppTheme.brandColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getFileExtension(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorSection() {
    return Expanded(
      child: Container(
        color: AppTheme.neutral900,
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _contentController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.white,
            height: 1.5,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '// 输入文件内容...\n// \n// 提示: 使用 Ctrl+S 快捷键保存文件',
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final content = _contentController.text;
    final lines = content.split('\n').length;
    final chars = content.length;
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        border: const Border(
          top: BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStatusItem(Icons.description, '$lines 行'),
          const SizedBox(width: 16),
          _buildStatusItem(Icons.text_fields, '$chars 字符'),
          const SizedBox(width: 16),
          _buildStatusItem(Icons.space_bar, '$words 词'),
          const Spacer(),
          if (_autoSaveEnabled)
            _buildStatusItem(Icons.save_alt, '自动保存已启用', color: AppTheme.successColor),
          if (!_autoSaveEnabled)
            _buildStatusItem(Icons.save_outlined, '自动保存已禁用', color: AppTheme.neutral600),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.neutral600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'py':
        return Icons.psychology;
      case 'js':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'html':
        return Icons.language;
      case 'css':
        return Icons.style;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension() {
    final path = _pathController.text.trim();
    if (path.isEmpty || !path.contains('.')) return 'txt';
    return path.split('.').last;
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningColor),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () {
              _writeFile();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brandColor),
            child: const Text('保存并离开'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    final content = _contentController.text;
    final lines = content.split('\n').length;
    final chars = content.length;
    final charsNoSpace = content.replaceAll(' ', '').replaceAll('\n', '').length;
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final paragraphs = content.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件统计'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('总行数', lines.toString()),
              _buildStatRow('总字符数', chars.toString()),
              _buildStatRow('字符数 (无空格)', charsNoSpace.toString()),
              _buildStatRow('单词数', words.toString()),
              _buildStatRow('段落数', paragraphs.toString()),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
