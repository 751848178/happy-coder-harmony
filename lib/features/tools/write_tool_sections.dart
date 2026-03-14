part of 'write_tool_screen.dart';

extension _WriteToolSections on _WriteToolScreenState {
  Widget _buildWritePathSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open, color: AppTheme.brandColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _pathController,
              decoration: InputDecoration(
                hintText: '输入文件路径 (例如: /path/to/file.txt)',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.neutral400),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
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
                  Icon(_getFileIcon(), size: 14, color: AppTheme.brandColor),
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

  Widget _buildWriteEditorSection() {
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

  Widget _buildWriteStatusBar() {
    final content = _contentController.text;
    final lines = content.split('\n').length;
    final chars = content.length;
    final words =
        content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.neutral100,
        border: Border(top: BorderSide(color: AppTheme.neutral200, width: 1)),
      ),
      child: Row(
        children: [
          _buildWriteStatusItem(Icons.description, '$lines 行'),
          const SizedBox(width: 16),
          _buildWriteStatusItem(Icons.text_fields, '$chars 字符'),
          const SizedBox(width: 16),
          _buildWriteStatusItem(Icons.space_bar, '$words 词'),
          const Spacer(),
          _buildWriteStatusItem(
            _autoSaveEnabled ? Icons.save_alt : Icons.save_outlined,
            _autoSaveEnabled ? '自动保存已启用' : '自动保存已禁用',
            color:
                _autoSaveEnabled ? AppTheme.successColor : AppTheme.neutral600,
          ),
        ],
      ),
    );
  }

  Widget _buildWriteStatusItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.neutral600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color ?? AppTheme.neutral600),
        ),
      ],
    );
  }
}
