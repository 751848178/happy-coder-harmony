part of 'file_viewer_screen.dart';

extension on _FileViewerScreenState {
  List<Widget> _buildAppBarActions() {
    return [
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
