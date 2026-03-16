part of 'command_palette.dart';

class DefaultCommands {
  static List<CommandItem> get all => [
        CommandItem(
          id: 'sessions',
          label: '会话列表',
          description: '查看所有会话',
          icon: Icons.chat_bubble_outline,
          type: CommandType.navigation,
        ),
        CommandItem(
          id: 'new-session',
          label: '新建会话',
          description: '创建新的聊天会话',
          icon: Icons.add_circle_outline,
          type: CommandType.action,
        ),
        CommandItem(
          id: 'friends',
          label: '好友',
          description: '管理好友列表',
          icon: Icons.people_outline,
          type: CommandType.navigation,
        ),
        CommandItem(
          id: 'inbox',
          label: '收件箱',
          description: '查看通知和消息',
          icon: Icons.inbox_outlined,
          type: CommandType.navigation,
        ),
        CommandItem(
          id: 'settings',
          label: '设置',
          description: '应用设置',
          icon: Icons.settings_outlined,
          type: CommandType.navigation,
          subcommands: const [
            CommandItem(
              id: 'settings-account',
              label: '账户设置',
              description: '管理账户信息',
              icon: Icons.account_circle_outlined,
              type: CommandType.settings,
            ),
            CommandItem(
              id: 'settings-appearance',
              label: '外观设置',
              description: '自定义主题和样式',
              icon: Icons.palette_outlined,
              type: CommandType.settings,
            ),
            CommandItem(
              id: 'settings-security',
              label: '安全设置',
              description: '隐私和安全选项',
              icon: Icons.security_outlined,
              type: CommandType.settings,
            ),
          ],
        ),
        CommandItem(
          id: 'profile',
          label: 'AI 配置',
          description: '管理 AI 模型配置',
          icon: Icons.psychology_outlined,
          type: CommandType.navigation,
        ),
        CommandItem(
          id: 'tools',
          label: '工具',
          description: '访问开发工具',
          icon: Icons.build_outlined,
          type: CommandType.action,
          subcommands: const [
            CommandItem(
              id: 'tools-bash',
              label: '终端',
              description: '执行 bash 命令',
              icon: Icons.terminal,
              type: CommandType.action,
            ),
            CommandItem(
              id: 'tools-edit',
              label: '编辑器',
              description: '代码编辑',
              icon: Icons.edit,
              type: CommandType.action,
            ),
            CommandItem(
              id: 'tools-write',
              label: '文件写入',
              description: '创建和编辑文件',
              icon: Icons.create,
              type: CommandType.action,
            ),
            CommandItem(
              id: 'tools-todo',
              label: '任务管理',
              description: '管理待办任务',
              icon: Icons.checklist,
              type: CommandType.action,
            ),
          ],
        ),
        CommandItem(
          id: 'logout',
          label: '退出登录',
          description: '退出当前账户',
          icon: Icons.logout_outlined,
          type: CommandType.action,
        ),
      ];
}
