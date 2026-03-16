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

const List<_InputTemplateItem> _defaultInputTemplates = [
  _InputTemplateItem(
    label: '解释这段代码',
    content: '请解释这段代码的功能和实现方式。',
    icon: Icons.lightbulb_outline_rounded,
  ),
  _InputTemplateItem(
    label: '添加注释',
    content: '请为这段代码添加清晰、简洁的注释。',
    icon: Icons.comment_outlined,
  ),
  _InputTemplateItem(
    label: '查找 Bug',
    content: '请帮我排查这段代码中可能存在的问题，并给出修复建议。',
    icon: Icons.bug_report_outlined,
  ),
  _InputTemplateItem(
    label: '性能优化',
    content: '请分析这段代码的性能瓶颈，并给出可落地的优化方案。',
    icon: Icons.speed_rounded,
  ),
  _InputTemplateItem(
    label: 'Code Review',
    content: '请帮我做一次代码审查，重点关注潜在 Bug、性能问题和可维护性。',
    icon: Icons.rate_review_outlined,
  ),
  _InputTemplateItem(
    label: '编写测试',
    content: '请为这段代码编写测试，覆盖主要场景和边界情况。',
    icon: Icons.science_outlined,
  ),
];

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
    required this.label,
    required this.content,
    required this.icon,
  });

  final String label;
  final String content;
  final IconData icon;
}
