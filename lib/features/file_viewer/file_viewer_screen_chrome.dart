part of 'file_viewer_screen.dart';

extension on _FileViewerScreenState {
  List<Widget> _buildAppBarActions() {
    if (_isEditing) {
      return [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.brandColor,
              ),
            ),
          )
        else ...[
          IconButton(
            onPressed: _exitEditMode,
            icon: const Icon(Icons.close),
            tooltip: '取消',
          ),
          IconButton(
            onPressed: _saveFileContent,
            icon: const Icon(Icons.check),
            tooltip: '保存',
          ),
        ],
      ];
    }
    return [
      if (_canEdit && !_isLoading && _content != null)
        IconButton(
          onPressed: _enterEditMode,
          icon: const Icon(Icons.edit_outlined),
          tooltip: '编辑',
        ),
      IconButton(
        onPressed: _isLoading ? null : _loadFileContent,
        icon: const Icon(Icons.refresh),
        tooltip: '刷新',
      ),
      if (_content != null && _content!.isNotEmpty)
        IconButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _content!));
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件内容已复制')),
            );
          },
          icon: const Icon(Icons.copy_outlined),
          tooltip: '复制',
        ),
    ];
  }
}

class _FileViewerAppBarTitle extends StatelessWidget {
  const _FileViewerAppBarTitle({
    required this.displayName,
    required this.displayPath,
  });

  final String displayName;
  final String? displayPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName.isEmpty ? '文件' : displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (displayPath != null && displayPath!.isNotEmpty)
          Text(
            displayPath!,
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
