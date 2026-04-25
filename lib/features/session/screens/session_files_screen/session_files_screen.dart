import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../session/data/session_files_provider.dart';
import '../../domain/session_files_models.dart';

part 'actions.dart';
part 'body.dart';
part 'support.dart';
part 'widgets.dart';

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
      _loadFiles(ref);
    });
  }

  void _loadFiles(WidgetRef ref) => _loadSessionFiles(this, ref);

  void _loadMore(WidgetRef ref) => _loadMoreSessionFiles(this, ref);

  void _showUploadDialog(BuildContext context) =>
      _showSessionFileUploadDialog(context);

  void _showDeleteDialog(BuildContext context, String fileId) =>
      _showSessionFileDeleteDialog(context, fileId);

  void _showFileDetail(
    BuildContext context,
    String fileId,
    String fileName,
    String? mimeType,
    String? filePath,
  ) =>
      _openSessionFileDetail(
        context,
        fileId: fileId,
        fileName: fileName,
        mimeType: mimeType,
        filePath: filePath,
      );

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
            onPressed: () => _loadFiles(ref),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showUploadDialog(context),
            tooltip: '上传文件',
          ),
        ],
      ),
      body: _buildSessionFilesBody(this, context, ref),
    );
  }
}
