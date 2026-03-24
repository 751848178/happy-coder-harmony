part of 'session_screen.dart';

class _ModeOption {
  const _ModeOption({
    required this.key,
    required this.label,
    this.description,
  });

  factory _ModeOption.fromSessionModeOption(SessionModeOption value) {
    return _ModeOption(
      key: value.key,
      label: value.label,
      description: value.description,
    );
  }

  final String key;
  final String label;
  final String? description;
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ModeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandColor.withValues(alpha: 0.08)
              : AppTheme.surface,
          border: Border.all(
            color: selected ? AppTheme.brandColor : AppTheme.neutral200,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.brandColor : AppTheme.neutral500,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.description != null &&
                      option.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Set<String> _ignoredSlashCommands = {
  'add-dir',
  'agents',
  'config',
  'statusline',
  'bashes',
  'settings',
  'cost',
  'doctor',
  'exit',
  'help',
  'ide',
  'init',
  'install-github-app',
  'mcp',
  'memory',
  'migrate-installer',
  'model',
  'pr-comments',
  'release-notes',
  'resume',
  'status',
  'bug',
  'review',
  'security-review',
  'terminal-setup',
  'upgrade',
  'vim',
  'permissions',
  'hooks',
  'export',
  'logout',
  'login',
};

const Map<String, String> _slashCommandDescriptions = {
  'compact': '压缩当前对话上下文',
  'clear': '清空当前会话消息',
  'reset': '重置当前会话',
  'debug': '查看调试信息',
  'status': '查看当前连接状态',
  'stop': '停止当前任务',
  'abort': '中止当前任务',
  'cancel': '取消当前任务',
};

final List<_InputTemplateItem> _defaultInputTemplates =
    List<_InputTemplateItem>.unmodifiable(
  defaultSessionInputTemplatePresets
      .map(
        (preset) => _InputTemplateItem(
          id: preset.id,
          label: preset.label,
          content: preset.content,
          icon: preset.icon,
        ),
      )
      .toList(growable: false),
);

class _SlashCommandItem {
  const _SlashCommandItem({
    required this.command,
    this.description,
  });

  final String command;
  final String? description;
}

class _InputTemplateItem {
  const _InputTemplateItem({
    required this.id,
    required this.label,
    required this.content,
    required this.icon,
    this.isCustom = false,
  });

  factory _InputTemplateItem.fromCustom(SessionInputTemplate template) {
    return _InputTemplateItem(
      id: template.id,
      label: template.label,
      content: template.content,
      icon: Icons.edit_note_rounded,
      isCustom: true,
    );
  }

  final String id;
  final String label;
  final String content;
  final IconData icon;
  final bool isCustom;
}

class _ComposerTriggerMatch {
  const _ComposerTriggerMatch({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}
