part of 'write_tool_screen.dart';

extension _WriteToolDialogs on _WriteToolScreenState {
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
              _updateState(() => _hasUnsavedChanges = false);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
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
    final charsNoSpace =
        content.replaceAll(' ', '').replaceAll('\n', '').length;
    final words =
        content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .length;

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
            style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
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
