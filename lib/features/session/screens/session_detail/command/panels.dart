part of '../session_detail.dart';

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
