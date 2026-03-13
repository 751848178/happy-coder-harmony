import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../session/data/session_files_provider.dart';
import '../domain/session_files_models.dart';

/// Session Files Screen
///
/// 显示会话关联的所有文件
class SessionFilesScreen extends ConsumerStatefulWidget {
  const SessionFilesScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionFilesScreen> createState() => _SessionFilesScreenState();
}

class _SessionFilesScreenState extends ConsumerState<SessionFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('会话文件'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFiles(context, ref),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showUploadDialog(context),
            tooltip: '上传文件',
          ),
        ],
      ),
      body: _FilesBody(context: context, ref: ref),
    );
  }

  Widget _FilesBody({required BuildContext context, required WidgetRef ref}) {
    final state = ref.watch(sessionFilesStateProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (state.hasError) {
      return _ErrorBody(
        errorMessage: state.error!,
        onRetry: () => _loadFiles(context, ref),
      );
    }

    if (state.files.isEmpty) {
      return _EmptyBody(onUpload: () => _showUploadDialog(context));
    }

    return Column(
      children: [
        // 文件列表
        Expanded(
          child: state.totalCount != null
              ? _FilesListWithCount(
                  files: state.files,
                  totalCount: state.totalCount!,
                  onLoadMore: state.nextCursor != null
                      ? () => _loadMore(context, ref)
                      : null,
                )
              : _FilesList(
                  files: state.files,
                  onLoadMore: () => _loadMore(context, ref),
                ),
        ),
        // 底部操作历史
        if (state.operations.isNotEmpty)
          Expanded(
            child: _OperationsPanel(operations: state.operations, files: state.files),
          ),
      ],
    );
  }

  Widget _FilesListWithCount({
    required List<SessionFile> files,
    required int totalCount,
    VoidCallback? onLoadMore,
  }) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileCard(
          file: file,
          onTap: () => _showFileDetail(context, file.id, file.fileName, file.mimeType, file.filePath),
          onDelete: () => _showDeleteDialog(context, file.id),
        );
      },
    );
  }

  Widget _FilesList({
    required List<SessionFile> files,
    required VoidCallback onLoadMore,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileCard(
          file: file,
          onTap: () => _showFileDetail(context, file.id, file.fileName, file.mimeType, file.filePath),
          onDelete: () => _showDeleteDialog(context, file.id),
        );
      },
    );
  }

  Widget _FileCard({
    required SessionFile file,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final sizeFormatted = file.size != null
          ? _formatSize(file.size!)
          : '未知大小';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_FileIcon(file.mimeType), size: 24, color: AppTheme.neutral600),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: AppTheme.neutral400),
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

  IconData _FileIcon(String? mimeType) {
    switch (mimeType?.toLowerCase()) {
      case 'text/plain':
      return Icons.description;
      case 'application/json':
        return Icons.code;
      case 'application/javascript':
      return Icons.javascript;
      case 'application/x-sh':
        return Icons.data_object;
      case 'application/x-python-code':
        return Icons.data_object;
      case 'application/yaml':
        return Icons.data_object;
      case 'application/json':
        return Icons.code;
      case 'image/png':
      return Icons.image;
      case 'image/jpeg':
        return Icons.image;
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

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Widget _OperationsPanel({
    required List<FileOperation> operations,
    required List<SessionFile> files,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 操作历史标题
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '操作历史',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral600,
              ),
            ),
          ),
          const Divider(),
          // 操作列表
          ...operations.map((op) => _OperationItem(op, files)).toList(),
        ],
      ),
    );
  }

  Widget _OperationItem(FileOperation op, List<SessionFile> files) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(_OperationIcon(op.operation), size: 16, color: AppTheme.neutral600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatOperationDescription(op, op.filePath),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(op.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _OperationIcon(FileOperationType type) {
    switch (type) {
      case FileOperationType.read:
        return Icons.visibility;
      case FileOperationType.write:
        return Icons.edit;
      case FileOperationType.delete:
        return Icons.delete_forever;
      default:
        return Icons.info_outline;
    }
  }

  String _formatOperationDescription(FileOperation op, String? filePath) {
    switch (op.operation) {
      case FileOperationType.read:
        return '读取文件';
      case FileOperationType.write:
        return filePath != null
              ? '写入: $filePath'
              : '创建文件';
      case FileOperationType.delete:
        return '删除文件';
      default:
        return '操作: ${op.operation}';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }

  void _loadFiles(BuildContext context, WidgetRef ref) {
    ref.read(sessionFilesStateProvider.notifier).loadFiles(
          sessionId: widget.sessionId,
        );
  }

  void _loadMore(BuildContext context, WidgetRef ref) {
    final state = ref.read(sessionFilesStateProvider);
    if (state.nextCursor == null) {
      return;
    }
    ref.read(sessionFilesStateProvider.notifier).loadFiles(
          sessionId: widget.sessionId,
          cursor: state.nextCursor,
        );
  }

  Widget _UploadDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_upload, size: 48, color: AppTheme.brandColor),
        const SizedBox(height: 16),
        const Text(
          '选择文件上传方式',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          '支持图片、文档等多种文件格式',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传文件'),
        content: _UploadDialogContent(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('从相册选择'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String fileId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文件'),
        content: const Text('确认要删除这个文件吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 调用删除 API
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

  void _showFileDetail(
    BuildContext context,
    String fileId,
    String fileName,
    String? mimeType,
    String? filePath,
  ) {
    final queryParams = {
      'id': fileId,
      'name': fileName,
      if (mimeType != null) 'mimeType': mimeType,
      if (filePath != null) 'path': filePath,
    };
    final query = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push('/file/view?$query');
  }

  Widget _EmptyBody({required VoidCallback onUpload}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '暂无文件',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('上传文件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ErrorBody({required String errorMessage, required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
