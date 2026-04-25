part of 'edit_tool_screen.dart';

extension _EditToolContent on _EditToolScreenState {
  Widget _buildEditor() {
    return Column(
      children: [
        _buildLanguageSelector(),
        const SizedBox(height: AppTheme.spacingMd),
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

  Widget _buildReadOnlyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBar(),
        const SizedBox(height: AppTheme.spacingMd),
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
          const Icon(Icons.edit_document, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Text(
            '编辑模式',
            style: TextStyle(
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
              _selectedLanguage,
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
        _updateState(() => _selectedLanguage = value);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'dart', child: Text('Dart')),
        PopupMenuItem(value: 'python', child: Text('Python')),
        PopupMenuItem(value: 'javascript', child: Text('JavaScript')),
      ],
    );
  }
}
