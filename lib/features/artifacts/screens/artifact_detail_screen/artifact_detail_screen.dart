import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../artifacts/data/artifact_provider.dart';
import '../../../artifacts/domain/artifact_display.dart';
import '../../../artifacts/domain/artifact_models.dart';

part 'content.dart';

/// Upstream-aligned artifact detail view.
class ArtifactDetailScreen extends ConsumerStatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.artifactId,
  });

  final String artifactId;

  @override
  ConsumerState<ArtifactDetailScreen> createState() =>
      _ArtifactDetailScreenState();
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

    final artifact = await ref
        .read(artifactStateProvider.notifier)
        .loadArtifact(widget.artifactId);
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
    final artifact =
        ref.watch(artifactStateProvider).artifacts.cast<Artifact?>().firstWhere(
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
              onPressed: () =>
                  context.push(AppRoutes.editArtifactWithId(artifact.id)),
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
}
