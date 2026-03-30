import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../session/data/session_input_template_service.dart';

Future<SessionInputTemplate?> showTemplateEditorDialog(
  BuildContext context, {
  required SessionInputTemplateService templateService,
  SessionInputTemplate? existing,
}) async {
  final labelController = TextEditingController(text: existing?.label ?? '');
  final contentController =
      TextEditingController(text: existing?.content ?? '');
  final result = await showDialog<SessionInputTemplate>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(existing == null ? '新建快捷模板' : '编辑快捷模板'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：生成日报',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '输入插入到会话中的模板内容',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final label = labelController.text.trim();
            final content = contentController.text.trim();
            if (label.isEmpty || content.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请先填写模板标题和内容'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
              return;
            }
            Navigator.pop(
              dialogContext,
              existing == null
                  ? templateService.createTemplate(
                      label: label,
                      content: content,
                    )
                  : existing.copyWith(
                      label: label,
                      content: content,
                    ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
  return result;
}

Future<bool> showDeleteTemplateConfirmDialog(
  BuildContext context, {
  required SessionInputTemplate template,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除快捷模板'),
      content: Text('确认删除模板「${template.label}」吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> showTemplatePreviewDialog(
  BuildContext context, {
  required String label,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(label),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: SelectableText(content),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
