import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Command action type
enum CommandType {
  navigation,
  action,
  search,
  settings,
}

/// Command item
class CommandItem {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> keywords;
  final CommandType type;
  final String? route;
  final VoidCallback? action;
  final List<CommandItem>? subcommands;

  const CommandItem({
    required this.id,
    required this.label,
    required this.icon,
    this.keywords = const [],
    this.type = CommandType.action,
    this.route,
    this.description = '',
    this.action,
    this.subcommands,
  });
}

/// Command Palette Widget
///
/// Provides a searchable command interface
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({
    super.key,
    required this.commands,
    this.onCommandSelected,
    this.placeholder = '输入命令...',
    this.visible = false,
    this.onClose,
  });

  final List<CommandItem> commands;
  final Function(CommandItem)? onCommandSelected;
  final String placeholder;
  final bool visible;
  final VoidCallback? onClose;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<CommandItem> _filteredCommands = [];
  int _selectedIndex = 0;
  CommandItem? _selectedCommand;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _filteredCommands = widget.commands;
  }

  @override
  void didUpdateWidget(CommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      // Opened
      _searchController.clear();
      _filteredCommands = widget.commands;
      _selectedIndex = 0;
      _focusNode.requestFocus();
    } else if (!widget.visible && oldWidget.visible) {
      // Closed
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredCommands = _filterCommands(query);
      _selectedIndex = 0;
    });
  }

  List<CommandItem> _filterCommands(String query) {
    if (query.isEmpty) {
      return widget.commands;
    }

    final results = <CommandItem>[];

    for (final command in widget.commands) {
      // Check main command
      if (_matchesCommand(command, query)) {
        results.add(command);
      }

      // Check subcommands
      if (command.subcommands != null) {
        for (final subcommand in command.subcommands!) {
          if (_matchesCommand(subcommand, query)) {
            // Add parent if not already added
            if (!results.any((c) => c.id == command.id)) {
              results.add(command);
            }
          }
        }
      }
    }

    return results;
  }

  bool _matchesCommand(CommandItem command, String query) {
    if (query.isEmpty) return true;

    final labelMatch = command.label.toLowerCase().contains(query);
    final keywordMatch = command.keywords.any((k) => k.toLowerCase().contains(query));
    final descMatch = command.description.toLowerCase().contains(query);

    return labelMatch || keywordMatch || descMatch;
  }

  void _selectCommand(CommandItem command) {
    if (command.subcommands != null && command.subcommands!.isNotEmpty) {
      // Has subcommands, expand or select from subcommands
      setState(() {
        _selectedCommand = command;
        _filteredCommands = command.subcommands!;
        _selectedIndex = 0;
        _searchController.clear();
      });
    } else {
      // Execute command
      if (command.action != null) {
        command.action!();
      }
      widget.onCommandSelected?.call(command);
      _close();
    }
  }

  void _goBack() {
    if (_selectedCommand != null) {
      setState(() {
        _selectedCommand = null;
        _filteredCommands = widget.commands;
        _selectedIndex = 0;
      });
    } else {
      _close();
    }
  }

  void _close() {
    _searchController.clear();
    widget.onClose?.call();
  }

  void _handleKeyDown(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = (event as KeyDownEvent).logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
        _scrollToSelected();
    } else if (key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
        });
        _scrollToSelected();
    } else if (key == LogicalKeyboardKey.enter) {
        if (_selectedIndex < _filteredCommands.length) {
          _selectCommand(_filteredCommands[_selectedIndex]);
        }
    } else if (key == LogicalKeyboardKey.backspace && _searchController.text.isEmpty && _selectedCommand != null) {
      _goBack();
    }
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients) {
      final itemHeight = 64.0;
      final targetOffset = _selectedIndex * itemHeight - _scrollController.position.viewportDimension / 2 + itemHeight / 2;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Actions(
        actions: <Type, Action<Intent>>{
          _EscapeIntent: CallbackAction<_EscapeIntent>(onInvoke: (_) => _close()),
          _ArrowDownIntent: CallbackAction<_ArrowDownIntent>(onInvoke: (_) {
            setState(() {
              _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
            });
            _scrollToSelected();
          }),
          _ArrowUpIntent: CallbackAction<_ArrowUpIntent>(onInvoke: (_) {
            setState(() {
              _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
            });
            _scrollToSelected();
          }),
          _EnterIntent: CallbackAction<_EnterIntent>(onInvoke: (_) {
            if (_selectedIndex < _filteredCommands.length) {
              _selectCommand(_filteredCommands[_selectedIndex]);
            }
          }),
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyDown,
          child: _CommandPaletteOverlay(
            visible: widget.visible,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchBar(),
                    _buildCommandList(),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: AppTheme.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.neutral500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppTheme.neutral400),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (_selectedCommand != null)
            TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.chevron_left),
              label: const Text('返回'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.neutral600),
            ),
        ],
      ),
    );
  }

  Widget _buildCommandList() {
    if (_filteredCommands.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppTheme.neutral400,
              ),
              const SizedBox(height: 16),
              const Text(
                '未找到匹配的命令',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = _filteredCommands.length > 8 ? 8 : _filteredCommands.length;
    final showScrollIndicator = _filteredCommands.length > 8;

    return SizedBox(
      height: 64.0 * itemCount + (showScrollIndicator ? 30 : 0),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final command = _filteredCommands[index];
          final isSelected = index == _selectedIndex;
          return _CommandItemWidget(
            command: command,
            isSelected: isSelected,
            onTap: () => _selectCommand(command),
          );
        },
      ),
    );
  }
}

/// Command item widget
class _CommandItemWidget extends StatelessWidget {
  const _CommandItemWidget({
    required this.command,
    required this.isSelected,
    required this.onTap,
  });

  final CommandItem command;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.brandColor
                    : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                command.icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.neutral600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    command.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.brandColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (command.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      command.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppTheme.brandColor.withValues(alpha: 0.7)
                            : AppTheme.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (command.subcommands != null && command.subcommands!.isNotEmpty)
              Icon(
                Icons.chevron_right,
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral400,
              ),
          ],
        ),
      ),
    );
  }
}

/// Command palette overlay
class _CommandPaletteOverlay extends StatelessWidget {
  const _CommandPaletteOverlay({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: visible
          ? Stack(
              children: [
                // Backdrop
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // Don't close on backdrop tap - let escape key handle it
                    },
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Content
                Center(child: child),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Intents for shortcuts
class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _ArrowDownIntent extends Intent {
  const _ArrowDownIntent();
}

class _ArrowUpIntent extends Intent {
  const _ArrowUpIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}

/// Default command palette commands
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
      subcommands: [
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
      subcommands: [
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
