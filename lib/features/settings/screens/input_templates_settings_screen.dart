import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../session/data/session_input_template_service.dart';
import '../../session/presentation/session_input_template_catalog.dart';

class InputTemplatesSettingsScreen extends StatefulWidget {
  const InputTemplatesSettingsScreen({super.key});

  @override
  State<InputTemplatesSettingsScreen> createState() =>
      _InputTemplatesSettingsScreenState();
}

class _InputTemplatesSettingsScreenState
    extends State<InputTemplatesSettingsScreen> {
  final SessionInputTemplateService _templateService =
      SessionInputTemplateService.instance;
  bool _isLoading = true;
  List<SessionInputTemplate> _customTemplates = const <SessionInputTemplate>[];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _templateService.loadTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _customTemplates = List<SessionInputTemplate>.unmodifiable(templates);
    });
  }

  Future<void> _showTemplateEditor({
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
                    ? _templateService.createTemplate(
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
    if (result == null) {
      return;
    }
    final templates = await _templateService.upsertTemplate(result);
    if (!mounted) {
      return;
    }
    setState(() {
      _customTemplates = List<SessionInputTemplate>.unmodifiable(templates);
    });
  }

  Future<void> _deleteTemplate(SessionInputTemplate template) async {
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
    if (confirmed != true) {
      return;
    }
    final templates = await _templateService.deleteTemplate(template.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _customTemplates = List<SessionInputTemplate>.unmodifiable(templates);
    });
  }

  Future<void> _showTemplatePreview({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('快捷模板'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _showTemplateEditor,
            icon: const Icon(Icons.add_rounded),
            tooltip: '新建模板',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _TemplateInfoCard(
                  onCreate: _showTemplateEditor,
                ),
                const SizedBox(height: 20),
                const _TemplateSectionTitle(title: '内置模板'),
                const SizedBox(height: 10),
                ...defaultSessionInputTemplatePresets.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TemplateTile(
                      icon: preset.icon,
                      title: preset.label,
                      content: preset.content,
                      tag: '内置',
                      onTap: () => _showTemplatePreview(
                        label: preset.label,
                        content: preset.content,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const _TemplateSectionTitle(title: '自定义模板'),
                const SizedBox(height: 10),
                if (_customTemplates.isEmpty)
                  _TemplateEmptyCard(onCreate: _showTemplateEditor)
                else
                  ..._customTemplates.map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateTile(
                        icon: Icons.edit_note_rounded,
                        title: template.label,
                        content: template.content,
                        onTap: () => _showTemplateEditor(existing: template),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showTemplateEditor(existing: template);
                              return;
                            }
                            _deleteTemplate(template);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('编辑'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('删除'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TemplateInfoCard extends StatelessWidget {
  const _TemplateInfoCard({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.brandColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '会话输入框里输入 ^，就会弹出这些快捷模板',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '内置模板可以直接用；自定义模板可以在这里新增、编辑和删除。',
            style: TextStyle(fontSize: 13, color: AppTheme.neutral700),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建自定义模板'),
          ),
        ],
      ),
    );
  }
}

class _TemplateSectionTitle extends StatelessWidget {
  const _TemplateSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.neutral700,
      ),
    );
  }
}

class _TemplateEmptyCard extends StatelessWidget {
  const _TemplateEmptyCard({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_add_outlined,
            size: 28,
            color: AppTheme.neutral500,
          ),
          const SizedBox(height: 10),
          const Text(
            '还没有自定义模板',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '可以把常用提示词存成模板，输入 ^ 就能快速插入。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('创建模板'),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
    this.tag,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String content;
  final VoidCallback onTap;
  final String? tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.brandColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
