part of 'session_screen.dart';

extension _SessionScreenViewCommandLogic on _SessionScreenState {
  List<_InputTemplateItem> _allInputTemplates() {
    return [
      ..._defaultInputTemplates,
      ..._customInputTemplates.map(_InputTemplateItem.fromCustom),
    ];
  }

  _ComposerTriggerMatch? _findComposerTrigger(String trigger) {
    final value = _messageController.value;
    final text = value.text;
    final selection = value.selection;
    final cursor = selection.isValid ? selection.end : text.length;
    if (cursor < 0 || cursor > text.length) {
      return null;
    }
    final prefix = text.substring(0, cursor);
    final triggerIndex = prefix.lastIndexOf(trigger);
    if (triggerIndex < 0) {
      return null;
    }
    final rawQuery = prefix.substring(triggerIndex + trigger.length);
    if (rawQuery.contains(RegExp(r'\s'))) {
      return null;
    }
    return _ComposerTriggerMatch(
      start: triggerIndex,
      end: cursor,
      query: rawQuery.trim().toLowerCase(),
    );
  }

  _ComposerTriggerMatch? _findInputTemplateTrigger() {
    return _findComposerTrigger('^');
  }

  void _showModeSheet({
    required String title,
    required List<_ModeOption> options,
    required _ModeOption current,
    required ValueChanged<_ModeOption> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaHeight = MediaQuery.sizeOf(context).height;
        final sheetHeight = (options.length * 76.0 + 140.0)
            .clamp(240.0, mediaHeight * 0.72)
            .toDouble();
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingMd),
                            child: _ModeOptionTile(
                              option: option,
                              selected: option.key == current.key,
                              onTap: () => onSelected(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_SlashCommandItem> _resolveSlashCommands(Session? session) {
    final metadataCommands = session?.metadata?['slashCommands'];
    final items = <_SlashCommandItem>[
      const _SlashCommandItem(
        command: 'compact',
        description: '压缩当前对话上下文',
      ),
      const _SlashCommandItem(
        command: 'clear',
        description: '清空当前会话消息',
      ),
    ];
    final seen = items.map((item) => item.command).toSet();
    if (metadataCommands is List) {
      for (final command in metadataCommands) {
        final value = command.toString().trim();
        if (value.isEmpty ||
            seen.contains(value) ||
            _ignoredSlashCommands.contains(value)) {
          continue;
        }
        items.add(
          _SlashCommandItem(
            command: value,
            description: _slashCommandDescriptions[value],
          ),
        );
        seen.add(value);
      }
    }
    return items;
  }

  List<_SlashCommandItem> _visibleSlashCommands(
    Session? session,
    bool enabled,
  ) {
    if (!enabled) {
      return const <_SlashCommandItem>[];
    }
    final text = _messageController.text.trimLeft();
    if (!text.startsWith('/')) {
      return const <_SlashCommandItem>[];
    }
    final rawQuery = text.substring(1);
    if (rawQuery.contains(' ')) {
      return const <_SlashCommandItem>[];
    }
    final query = rawQuery.trim().toLowerCase();
    final commands = _resolveSlashCommands(session);
    if (query.isEmpty) {
      return commands;
    }
    return commands
        .where(
          (item) =>
              item.command.toLowerCase().contains(query) ||
              (item.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  bool _shouldShowSlashCommands(List<_SlashCommandItem> commands) {
    return _messageController.text.trimLeft().startsWith('/') &&
        commands.isNotEmpty;
  }

  List<_InputTemplateItem> _visibleInputTemplates() {
    final triggerMatch = _findInputTemplateTrigger();
    if (triggerMatch == null) {
      return const <_InputTemplateItem>[];
    }
    final query = triggerMatch.query;
    final templates = _allInputTemplates();
    if (query.isEmpty) {
      return templates;
    }
    return templates
        .where(
          (item) =>
              item.label.toLowerCase().contains(query) ||
              item.content.toLowerCase().contains(query),
        )
        .toList();
  }

  bool _shouldShowInputTemplates(List<_InputTemplateItem> templates) {
    return _findInputTemplateTrigger() != null && templates.isNotEmpty;
  }
}
