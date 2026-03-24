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
          id: 'settings',
          label: '设置',
          description: '应用设置',
          icon: Icons.settings_outlined,
          type: CommandType.navigation,
        ),
      ];
}
