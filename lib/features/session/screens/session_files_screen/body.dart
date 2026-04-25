part of 'session_files_screen.dart';

Widget _buildSessionFilesBody(
  _SessionFilesScreenState state,
  BuildContext context,
  WidgetRef ref,
) {
  final filesState = ref.watch(sessionFilesStateProvider);
  if (filesState.isLoading) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.brandColor),
    );
  }
  if (filesState.hasError) {
    return _ErrorBody(
      errorMessage: filesState.error!,
      onRetry: () => state._loadFiles(ref),
    );
  }
  if (filesState.files.isEmpty) {
    return _EmptyBody(onUpload: () => state._showUploadDialog(context));
  }
  return Column(
    children: [
      Expanded(
        child: _SessionFilesList(
          files: filesState.files,
          onLoadMore:
              filesState.nextCursor == null ? null : () => state._loadMore(ref),
          onOpenFile: (file) => state._showFileDetail(
            context,
            file.id,
            file.fileName,
            file.mimeType,
            file.filePath,
          ),
          onDeleteFile: (file) => state._showDeleteDialog(context, file.id),
        ),
      ),
      if (filesState.operations.isNotEmpty)
        Expanded(
          child: _OperationsPanel(
            operations: filesState.operations,
            files: filesState.files,
          ),
        ),
    ],
  );
}

class _SessionFilesList extends StatelessWidget {
  const _SessionFilesList({
    required this.files,
    required this.onOpenFile,
    required this.onDeleteFile,
    this.onLoadMore,
  });

  final List<SessionFile> files;
  final void Function(SessionFile file) onOpenFile;
  final void Function(SessionFile file) onDeleteFile;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileCard(
          file: file,
          onTap: () => onOpenFile(file),
          onDelete: () => onDeleteFile(file),
        );
      },
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({
    required this.operations,
    required this.files,
  });

  final List<FileOperation> operations;
  final List<SessionFile> files;

  @override
  Widget build(BuildContext context) {
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
          ...operations
              .map((operation) => _OperationItem(operation: operation)),
        ],
      ),
    );
  }
}

class _OperationItem extends StatelessWidget {
  const _OperationItem({required this.operation});

  final FileOperation operation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(
            _sessionFileOperationIcon(operation.operation),
            size: 16,
            color: AppTheme.neutral600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSessionFileOperationDescription(
                    operation,
                    operation.filePath,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSessionFileTimestamp(operation.timestamp),
                  style: const TextStyle(
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
}
