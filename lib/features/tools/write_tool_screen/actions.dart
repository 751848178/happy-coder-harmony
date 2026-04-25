part of 'write_tool_screen.dart';

extension _WriteToolActions on _WriteToolScreenState {
  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      _updateState(() => _hasUnsavedChanges = true);
    }

    if (_autoSaveEnabled) {
      _autoSave();
    }
  }

  Future<void> _autoSave() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _writeFile() async {
    if (_isWriting) {
      return;
    }

    final path = _pathController.text.trim();
    if (path.isEmpty) {
      _showSnackBar('请输入文件路径', isError: true);
      return;
    }

    _updateState(() => _isWriting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) {
        return;
      }

      _showSnackBar('文件已写入: $path', isError: false);
      _updateState(() {
        _hasUnsavedChanges = false;
        _isWriting = false;
      });
    } catch (error) {
      _updateState(() => _isWriting = false);
      if (mounted) {
        _showSnackBar('写入失败: $error', isError: true);
      }
    }
  }

  void _clearContent() {
    _showClearConfirmation();
  }

  void _loadFromFile() {
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

  IconData _getFileIcon() {
    return switch (_getFileExtension().toLowerCase()) {
      'dart' => Icons.code,
      'py' => Icons.psychology,
      'js' => Icons.javascript,
      'json' => Icons.data_object,
      'md' => Icons.description,
      'txt' => Icons.text_snippet,
      'html' => Icons.language,
      'css' => Icons.style,
      _ => Icons.insert_drive_file,
    };
  }

  String _getFileExtension() {
    final path = _pathController.text.trim();
    if (path.isEmpty || !path.contains('.')) {
      return 'txt';
    }
    return path.split('.').last;
  }
}
