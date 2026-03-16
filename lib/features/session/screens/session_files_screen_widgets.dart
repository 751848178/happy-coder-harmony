part of 'session_files_screen.dart';

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  final SessionFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sizeFormatted =
        file.size != null ? _formatSessionFileSize(file.size!) : '未知大小';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_sessionFileIcon(file.mimeType),
                  size: 24, color: AppTheme.neutral600),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeFormatted,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.neutral600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever,
                    color: AppTheme.neutral400),
                onPressed: onDelete,
                tooltip: '删除',
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _sessionFileIcon(String? mimeType) {
  switch (mimeType?.toLowerCase()) {
    case 'text/plain':
      return Icons.description;
    case 'application/json':
      return Icons.code;
    case 'application/javascript':
    case 'application/x-sh':
    case 'application/x-python-code':
    case 'application/yaml':
      return Icons.data_object;
    case 'image/png':
    case 'image/jpeg':
    case 'image/svg+xml':
      return Icons.image;
    case 'application/pdf':
      return Icons.picture_as_pdf;
    case 'application/zip':
      return Icons.folder_zip;
    default:
      return Icons.insert_drive_file;
  }
}

String _formatSessionFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

IconData _sessionFileOperationIcon(FileOperationType type) {
  switch (type) {
    case FileOperationType.read:
      return Icons.visibility;
    case FileOperationType.write:
      return Icons.edit;
    case FileOperationType.delete:
      return Icons.delete_forever;
  }
}

String _formatSessionFileOperationDescription(
  FileOperation operation,
  String? filePath,
) {
  switch (operation.operation) {
    case FileOperationType.read:
      return '读取文件';
    case FileOperationType.write:
      return filePath == null ? '创建文件' : '写入: $filePath';
    case FileOperationType.delete:
      return '删除文件';
  }
}

String _formatSessionFileTimestamp(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 1) {
    return '刚刚';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} 分钟前';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} 小时前';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} 天前';
  }
  return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
}
