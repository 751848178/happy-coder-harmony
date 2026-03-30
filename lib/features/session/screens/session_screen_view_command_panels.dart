part of 'session_screen.dart';

extension _SessionScreenViewCommandPanels on _SessionScreenState {
  double _resolveSuggestionPanelMaxHeight({
    required double expandedHeight,
    required double compactMinHeight,
    required double compactMaxHeight,
  }) {
    final media = MediaQuery.of(context);
    if (media.viewInsets.bottom <= 0) {
      return expandedHeight;
    }
    return (media.size.height * 0.24)
        .clamp(compactMinHeight, compactMaxHeight)
        .toDouble();
  }

  void _applyInputTemplate(_InputTemplateItem item) {
    final triggerMatch = _findInputTemplateTrigger();
    if (triggerMatch == null) {
      _setComposerText(item.content);
      _messageFocusNode.requestFocus();
      return;
    }
    _replaceComposerSelection(
      start: triggerMatch.start,
      end: triggerMatch.end,
      replacement: item.content,
    );
  }

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
    _updateState(() {
      _customInputTemplates =
          List<SessionInputTemplate>.unmodifiable(templates);
    });
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
    _updateState(() {
      _customInputTemplates =
          List<SessionInputTemplate>.unmodifiable(templates);
    });
  }

  Widget _buildSlashCommandPanel(List<_SlashCommandItem> commands) {
    final maxHeight = _resolveSuggestionPanelMaxHeight(
      expandedHeight: 220,
      compactMinHeight: 112,
      compactMaxHeight: 168,
    );
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: commands.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppTheme.neutral200,
        ),
        itemBuilder: (context, index) {
          final item = commands[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.code_rounded, size: 18),
            title: Text(
              '/${item.command}',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamilyMono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: item.description == null
                ? null
                : Text(
                    item.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
            onTap: () {
              final value = '/${item.command} ';
              _messageController.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInputTemplatePanel(List<_InputTemplateItem> templates) {
    final maxHeight = _resolveSuggestionPanelMaxHeight(
      expandedHeight: 320,
      compactMinHeight: 148,
      compactMaxHeight: 208,
    );
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppTheme.brandColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '快捷模板 ${templates.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showInputTemplateEditor,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('自定义'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: templates.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppTheme.neutral200,
              ),
              itemBuilder: (context, index) {
                final item = templates[index];
                return ListTile(
                  dense: true,
                  leading:
                      Icon(item.icon, size: 18, color: AppTheme.brandColor),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: item.isCustom
                      ? PopupMenuButton<String>(
                          tooltip: '更多操作',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showInputTemplateEditor(existing: item);
                                break;
                              case 'delete':
                                _deleteInputTemplate(item);
                                break;
                            }
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
                        )
                      : null,
                  onTap: () => _applyInputTemplate(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
