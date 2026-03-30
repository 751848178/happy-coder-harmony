import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../artifacts/data/artifact_provider.dart';
import '../../artifacts/domain/artifact_display.dart';
import '../../artifacts/domain/artifact_models.dart';

part 'edit_artifact_screen_content.dart';

/// Upstream-aligned artifact edit flow: title + body only.
class EditArtifactScreen extends ConsumerStatefulWidget {
  const EditArtifactScreen({
    super.key,
    required this.artifactId,
  });

  final String artifactId;

  @override
  ConsumerState<EditArtifactScreen> createState() => _EditArtifactScreenState();
}

class _EditArtifactScreenState extends ConsumerState<EditArtifactScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Artifact? _artifact;
  String? _error;

  void _markDirty() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtifact();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (_artifact == null) {
      return false;
    }
    final originalTitle = artifactDisplayTitle(_artifact!);
    final originalBody = _artifact!.body ?? '';
    return _titleController.text.trim() !=
            (originalTitle == 'Untitled' ? '' : originalTitle) ||
        _bodyController.text.trim() != originalBody.trim();
  }

  Future<void> _loadArtifact() async {
    final artifact = await ref
        .read(artifactStateProvider.notifier)
        .loadArtifact(widget.artifactId);
    if (!mounted) {
      return;
    }

    setState(() {
      _artifact = artifact;
      _isLoading = false;
      _error = artifact == null ? '工件不存在或加载失败' : null;
      _titleController.text =
          artifact == null || artifactDisplayTitle(artifact) == 'Untitled'
              ? ''
              : artifactDisplayTitle(artifact);
      _bodyController.text = artifact?.body ?? '';
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
        title: const Text('编辑工件'),
        actions: [
          TextButton(
            onPressed: (_isSaving || !_hasChanges) ? null : _saveArtifact,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _saveArtifact() async {
    if (_artifact == null || _isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题和正文至少填写一项')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated =
          await ref.read(artifactStateProvider.notifier).updateArtifact(
                _artifact!.id,
                UpdateArtifactRequest(
                  header: jsonEncode({
                    if (title.isNotEmpty) 'title': title,
                  }),
                  headerVersion: _artifact!.headerVersion,
                  body: body.isEmpty ? null : body,
                  bodyVersion: _artifact!.bodyVersion,
                ),
              );

      if (!mounted) {
        return;
      }

      if (updated == null) {
        throw Exception('保存失败');
      }

      context.go(AppRoutes.artifact(updated.id));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $error')),
      );
      setState(() => _isSaving = false);
    }
  }
}
