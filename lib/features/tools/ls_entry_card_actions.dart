part of 'ls_tool_screen.dart';

extension _EntryCardActions on _EntryCard {
  void _showEntryMenu(BuildContext context, DirectoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEntryHeader(entry),
            const Divider(),
            _MenuItem(
              icon: Icons.open_in_new,
              label: '打开',
              onTap: () => Navigator.pop(context),
            ),
            if (!entry.isDirectory) _buildDownloadItem(context, entry),
            if (!entry.isDirectory) _buildCopyPathItem(context, entry),
            _MenuItem(
              icon: Icons.info_outline,
              label: '详细信息',
              onTap: () {
                Navigator.pop(context);
                _showEntryDetails(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryHeader(DirectoryEntry entry) {
    return Row(
      children: [
        Icon(entry.isDirectory ? Icons.folder : _getFileIcon(entry.name),
            size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                entry.isDirectory ? '目录' : '文件',
                style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _MenuItem _buildDownloadItem(BuildContext context, DirectoryEntry entry) {
    return _MenuItem(
      icon: Icons.file_download,
      label: '下载',
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载功能开发中')),
        );
      },
    );
  }

  _MenuItem _buildCopyPathItem(BuildContext context, DirectoryEntry entry) {
    return _MenuItem(
      icon: Icons.copy,
      label: '复制路径',
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制: ${entry.path}')),
        );
      },
    );
  }

  void _showEntryDetails(BuildContext context, DirectoryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('路径', entry.path),
            _DetailRow('类型', entry.isDirectory ? '目录' : '文件'),
            if (!entry.isDirectory && entry.size != null)
              _DetailRow('大小', _formatSize(entry.size!)),
            if (entry.modifiedAt != null)
              _DetailRow('修改时间', _formatDate(entry.modifiedAt!)),
            if (entry.permissions != null) _DetailRow('权限', entry.permissions!),
          ],
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

  IconData _getFileIcon(String name) {
    return switch (name.split('.').last.toLowerCase()) {
      'dart' => Icons.code,
      'js' || 'ts' => Icons.javascript,
      'py' => Icons.data_object,
      'json' || 'yaml' || 'yml' => Icons.description,
      'md' => Icons.article,
      'png' || 'jpg' || 'jpeg' || 'gif' => Icons.image,
      'pdf' => Icons.picture_as_pdf,
      _ => Icons.insert_drive_file,
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    }
    return '${date.month}/${date.day}';
  }
}
