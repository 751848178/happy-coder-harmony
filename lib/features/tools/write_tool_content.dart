part of 'write_tool_screen.dart';

extension _WriteToolContent on _WriteToolScreenState {
  Widget _buildScaffold() {
    return Scaffold(
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
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.5),
                ),
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
            onChanged: (value) => _updateState(() => _autoSaveEnabled = value),
            activeThumbColor: AppTheme.brandColor,
          ),
          Text(
            '自动保存',
            style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
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
              if (value == 'new') {
                _pathController.clear();
                _contentController.clear();
                return;
              }
              if (value == 'copy') {
                _showSnackBar('内容已复制', isError: false);
                return;
              }
              _showStatsDialog();
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
          _buildWritePathSection(),
          _buildWriteEditorSection(),
          _buildWriteStatusBar(),
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
    );
  }
}
