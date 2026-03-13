import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../artifacts/data/artifact_provider.dart';
import '../../artifacts/domain/artifact_display.dart';
import '../../artifacts/domain/artifact_models.dart';

/// Upstream-aligned artifact detail view.
class ArtifactDetailScreen extends ConsumerStatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.artifactId,
  });

  final String artifactId;

  @override
  ConsumerState<ArtifactDetailScreen> createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends ConsumerState<ArtifactDetailScreen> {
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtifact();
    });
  }

  Future<void> _loadArtifact() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final artifact = await ref.read(artifactStateProvider.notifier).loadArtifact(widget.artifactId);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (artifact == null) {
        _error = '工件不存在或加载失败';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final artifact = ref.watch(artifactStateProvider).artifacts.cast<Artifact?>().firstWhere(
          (item) => item?.id == widget.artifactId,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(artifact == null ? '工件' : artifactDisplayTitle(artifact)),
        actions: [
          if (artifact != null) ...[
            IconButton(
              onPressed: () => context.push(AppRoutes.editArtifactWithId(artifact.id)),
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
            ),
            IconButton(
              onPressed: _isDeleting ? null : () => _deleteArtifact(artifact),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: '删除',
            ),
          ],
        ],
      ),
      body: _buildBody(artifact),
    );
  }

  Widget _buildBody(Artifact? artifact) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_error != null || artifact == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? '工件不存在',
            style: const TextStyle(
              color: AppTheme.neutral600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final body = artifact.body?.trim();
    final description = artifactDisplayDescription(artifact);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          artifactDisplayTitle(artifact),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTimestamp(artifact.updatedAt),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral700,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: body == null || body.isEmpty
              ? const Text(
                  'No content',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.neutral600,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : MarkdownBody(
                  data: body,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppTheme.textPrimary,
                    ),
                    code: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _deleteArtifact(Artifact artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除工件'),
        content: Text('确认删除“${artifactDisplayTitle(artifact)}”吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);
    await ref.read(artifactStateProvider.notifier).deleteArtifact(artifact.id);
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.artifacts);
  }

  String _formatTimestamp(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
