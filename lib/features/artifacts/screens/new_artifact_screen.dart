import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../artifacts/data/artifact_provider.dart';
import '../../artifacts/domain/artifact_models.dart';

/// Upstream-aligned new artifact flow: title + body only.
class NewArtifactScreen extends ConsumerStatefulWidget {
  const NewArtifactScreen({super.key});

  @override
  ConsumerState<NewArtifactScreen> createState() => _NewArtifactScreenState();
}

class _NewArtifactScreenState extends ConsumerState<NewArtifactScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _bodyController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('新建工件'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveArtifact,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InputSection(
            label: '标题',
            child: TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('例如：重构后的路由梳理'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          _InputSection(
            label: '正文',
            child: TextField(
              controller: _bodyController,
              minLines: 12,
              maxLines: 20,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('在这里记录工件内容'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (!_hasContent)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '标题和正文至少填写一项。',
                style: TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _saveArtifact() async {
    if (_isSaving) {
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
      final artifact = await ref.read(artifactStateProvider.notifier).createArtifact(
            CreateArtifactRequest(
              id: _generateArtifactId(),
              header: jsonEncode({
                if (title.isNotEmpty) 'title': title,
              }),
              body: body.isEmpty ? null : body,
              dataEncryptionKey: _generateEncryptionKey(),
            ),
          );

      if (!mounted) {
        return;
      }

      if (artifact == null) {
        throw Exception('创建工件失败');
      }

      context.go(AppRoutes.artifact(artifact.id));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  String _generateArtifactId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    return 'art_${timestamp}_$microseconds';
  }

  String _generateEncryptionKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return base64.encode(List<int>.generate(32, (index) => (timestamp + index) % 256));
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
