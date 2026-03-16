part of 'session_files_screen.dart';

void _loadSessionFiles(
  _SessionFilesScreenState state,
  WidgetRef ref,
) {
  ref.read(sessionFilesStateProvider.notifier).loadFiles(
        sessionId: state.widget.sessionId,
      );
}

void _loadMoreSessionFiles(
  _SessionFilesScreenState state,
  WidgetRef ref,
) {
  final currentState = ref.read(sessionFilesStateProvider);
  if (currentState.nextCursor == null) {
    return;
  }
  ref.read(sessionFilesStateProvider.notifier).loadFiles(
        sessionId: state.widget.sessionId,
        cursor: currentState.nextCursor,
      );
}

void _showSessionFileUploadDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('上传文件'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload, size: 48, color: AppTheme.brandColor),
          const SizedBox(height: 16),
          const Text('选择文件上传方式', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            '支持图片、文档等多种文件格式',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('从相册选择'),
        ),
      ],
    ),
  );
}

void _showSessionFileDeleteDialog(BuildContext context, String fileId) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除文件'),
      content: const Text('确认要删除这个文件吗？此操作不可恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件已删除')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}

void _openSessionFileDetail(
  BuildContext context, {
  required String fileId,
  required String fileName,
  String? mimeType,
  String? filePath,
}) {
  final queryParams = {
    'id': fileId,
    'name': fileName,
    if (mimeType != null) 'mimeType': mimeType,
    if (filePath != null) 'path': filePath,
  };
  final query = queryParams.entries
      .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
      .join('&');
  context.push('/file/view?$query');
}
