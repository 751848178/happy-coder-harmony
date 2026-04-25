import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../session/data/session_input_template_service.dart';
import '../../../session/presentation/session_input_template_catalog.dart';
import 'dialogs.dart';
import 'widgets.dart';

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
    final result = await showTemplateEditorDialog(
      context,
      templateService: _templateService,
      existing: existing,
    );
    if (result == null || !mounted) {
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
    final confirmed = await showDeleteTemplateConfirmDialog(
      context,
      template: template,
    );
    if (!confirmed || !mounted) {
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
    return showTemplatePreviewDialog(
      context,
      label: label,
      content: content,
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
                TemplateInfoCard(
                  onCreate: _showTemplateEditor,
                ),
                const SizedBox(height: 20),
                const TemplateSectionTitle(title: '内置模板'),
                const SizedBox(height: 10),
                ...defaultSessionInputTemplatePresets.map(
                  (preset) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TemplateTile(
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
                const TemplateSectionTitle(title: '自定义模板'),
                const SizedBox(height: 10),
                if (_customTemplates.isEmpty)
                  TemplateEmptyCard(onCreate: _showTemplateEditor)
                else
                  ..._customTemplates.map(
                    (template) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TemplateTile(
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
