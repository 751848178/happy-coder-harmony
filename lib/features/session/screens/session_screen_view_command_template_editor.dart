part of 'session_screen.dart';

extension _SessionScreenTemplateEditor on _SessionScreenState {
  Future<void> _showInputTemplateEditor({
    _InputTemplateItem? existing,
    String? initialLabel,
    String? initialContent,
  }) async {
    final labelController = TextEditingController(
      text: existing?.label ?? initialLabel ?? '',
    );
    final contentController =
        TextEditingController(text: existing?.content ?? initialContent ?? '');
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
                    ? _inputTemplateService.createTemplate(
                        label: label,
                        content: content,
                      )
                    : SessionInputTemplate(
                        id: existing.id,
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
    if (result == null) {
      return;
    }
    final templates = await _inputTemplateService.upsertTemplate(result);
    if (!mounted) {
      return;
    }
    _customInputTemplatesN.value =
        List<SessionInputTemplate>.unmodifiable(templates);
  }

  Future<void> _deleteInputTemplate(_InputTemplateItem item) async {
    if (!item.isCustom) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除快捷模板'),
        content: Text('确认删除模板「${item.label}」吗？'),
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
    if (confirmed != true) {
      return;
    }
    final templates = await _inputTemplateService.deleteTemplate(item.id);
    if (!mounted) {
      return;
    }
    _customInputTemplatesN.value =
        List<SessionInputTemplate>.unmodifiable(templates);
  }
}
