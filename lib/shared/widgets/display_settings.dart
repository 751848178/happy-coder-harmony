import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Compact view option provider
final compactViewProvider = StateProvider<bool>((ref) => false);

/// Inline tool calls option provider
final inlineToolCallsProvider = StateProvider<bool>((ref) => true);

/// Expand todo list option provider
final expandTodoListProvider = StateProvider<bool>((ref) => true);

/// Show line numbers option provider
final showLineNumbersProvider = StateProvider<bool>((ref) => true);

/// Auto wrap option provider
final autoWrapProvider = StateProvider<bool>((ref) => false);

/// Always show context size option provider
final alwaysShowContextSizeProvider = StateProvider<bool>((ref) => false);

/// Avatar style option provider
final avatarStyleOptionProvider = StateProvider<String>((ref) => 'gradient');

/// Show flavor icon option provider
final showFlavorIconProvider = StateProvider<bool>((ref) => true);

/// Display Settings Widget
///
/// Provides options for customizing display preferences
class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('显示设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('会话视图'),
          const SizedBox(height: 8),
          _CompactViewOption(),
          const SizedBox(height: 8),
          _InlineToolCallsOption(),
          const SizedBox(height: 8),
          _ExpandTodoListOption(),
          const SizedBox(height: 24),

          _buildSectionHeader('代码编辑'),
          const SizedBox(height: 8),
          _ShowLineNumbersOption(),
          const SizedBox(height: 8),
          _AutoWrapOption(),
          const SizedBox(height: 8),
          _AlwaysShowContextSizeOption(),
          const SizedBox(height: 24),

          _buildSectionHeader('用户界面'),
          const SizedBox(height: 8),
          _AvatarStyleOption(),
          const SizedBox(height: 8),
          _ShowFlavorIconOption(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Compact view option
class _CompactViewOption extends ConsumerWidget {
  const _CompactViewOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compactView = ref.watch(compactViewProvider);

    return Card(
      child: SwitchListTile(
        value: compactView,
        onChanged: (value) {
          ref.read(compactViewProvider.notifier).state = value;
        },
        title: const Text('紧凑会话视图'),
        subtitle: const Text(
          '在会话列表中使用更紧凑的布局',
        ),
        secondary: Icon(
          Icons.view_list,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Inline tool calls option
class _InlineToolCallsOption extends ConsumerWidget {
  const _InlineToolCallsOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inlineToolCalls = ref.watch(inlineToolCallsProvider);

    return Card(
      child: SwitchListTile(
        value: inlineToolCalls,
        onChanged: (value) {
          ref.read(inlineToolCallsProvider.notifier).state = value;
        },
        title: const Text('内联工具调用'),
        subtitle: const Text(
          '在聊天中内联显示工具调用结果',
        ),
        secondary: Icon(
          Icons.integration_instructions,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Expand todo list option
class _ExpandTodoListOption extends ConsumerWidget {
  const _ExpandTodoListOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandTodo = ref.watch(expandTodoListProvider);

    return Card(
      child: SwitchListTile(
        value: expandTodo,
        onChanged: (value) {
          ref.read(expandTodoListProvider.notifier).state = value;
        },
        title: const Text('展开 Todo 列表'),
        subtitle: const Text(
          '默认展开聊天中的待办事项',
        ),
        secondary: Icon(
          Icons.playlist_add_check,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Show line numbers option
class _ShowLineNumbersOption extends ConsumerWidget {
  const _ShowLineNumbersOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showLineNumbers = ref.watch(showLineNumbersProvider);

    return Card(
      child: SwitchListTile(
        value: showLineNumbers,
        onChanged: (value) {
          ref.read(showLineNumbersProvider.notifier).state = value;
        },
        title: const Text('显示行号'),
        subtitle: const Text(
          '在代码差异视图中显示行号',
        ),
        secondary: Icon(
          Icons.format_list_numbered,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Auto wrap option
class _AutoWrapOption extends ConsumerWidget {
  const _AutoWrapOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoWrap = ref.watch(autoWrapProvider);

    return Card(
      child: SwitchListTile(
        value: autoWrap,
        onChanged: (value) {
          ref.read(autoWrapProvider.notifier).state = value;
        },
        title: const Text('自动换行'),
        subtitle: const Text(
          '长代码行自动换行显示',
        ),
        secondary: Icon(
          Icons.wrap_text,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Always show context size option
class _AlwaysShowContextSizeOption extends ConsumerWidget {
  const _AlwaysShowContextSizeOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alwaysShowContext = ref.watch(alwaysShowContextSizeProvider);

    return Card(
      child: SwitchListTile(
        value: alwaysShowContext,
        onChanged: (value) {
          ref.read(alwaysShowContextSizeProvider.notifier).state = value;
        },
        title: const Text('始终显示上下文大小'),
        subtitle: const Text(
          '在所有会话中显示上下文使用情况',
        ),
        secondary: Icon(
          Icons.data_usage,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Avatar style option
class _AvatarStyleOption extends ConsumerWidget {
  const _AvatarStyleOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarStyle = ref.watch(avatarStyleOptionProvider);

    return Card(
      child: ListTile(
        title: const Text('头像样式'),
        subtitle: const Text(
          '选择用户头像显示风格',
        ),
        trailing: DropdownButton<String>(
          value: avatarStyle,
          items: const [
            DropdownMenuItem(
              value: 'gradient',
              child: Text('渐变'),
            ),
            DropdownMenuItem(
              value: 'pixelated',
              child: Text('像素'),
            ),
            DropdownMenuItem(
              value: 'brutalist',
              child: Text('粗野'),
            ),
            DropdownMenuItem(
              value: 'minimalist',
              child: Text('极简'),
            ),
            DropdownMenuItem(
              value: 'glass',
              child: Text('毛玻璃'),
            ),
            DropdownMenuItem(
              value: 'outline',
              child: Text('轮廓'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(avatarStyleOptionProvider.notifier).state = value;
            }
          },
        ),
      ),
    );
  }
}

/// Show flavor icon option
class _ShowFlavorIconOption extends ConsumerWidget {
  const _ShowFlavorIconOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFlavorIcon = ref.watch(showFlavorIconProvider);

    return Card(
      child: SwitchListTile(
        value: showFlavorIcon,
        onChanged: (value) {
          ref.read(showFlavorIconProvider.notifier).state = value;
        },
        title: const Text('显示 Flavor 图标'),
        subtitle: const Text(
          '在会话中显示模型类型图标',
        ),
        secondary: Icon(
          Icons.psychology,
          color: AppTheme.neutral500,
        ),
      ),
    );
  }
}

/// Display settings model for persistence
class DisplaySettings {
  final bool compactView;
  final bool inlineToolCalls;
  final bool expandTodoList;
  final bool showLineNumbers;
  final bool autoWrap;
  final bool alwaysShowContextSize;
  final String avatarStyle;
  final bool showFlavorIcon;

  const DisplaySettings({
    this.compactView = false,
    this.inlineToolCalls = true,
    this.expandTodoList = true,
    this.showLineNumbers = true,
    this.autoWrap = false,
    this.alwaysShowContextSize = false,
    this.avatarStyle = 'gradient',
    this.showFlavorIcon = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'compactView': compactView,
      'inlineToolCalls': inlineToolCalls,
      'expandTodoList': expandTodoList,
      'showLineNumbers': showLineNumbers,
      'autoWrap': autoWrap,
      'alwaysShowContextSize': alwaysShowContextSize,
      'avatarStyle': avatarStyle,
      'showFlavorIcon': showFlavorIcon,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      compactView: json['compactView'] ?? false,
      inlineToolCalls: json['inlineToolCalls'] ?? true,
      expandTodoList: json['expandTodoList'] ?? true,
      showLineNumbers: json['showLineNumbers'] ?? true,
      autoWrap: json['autoWrap'] ?? false,
      alwaysShowContextSize: json['alwaysShowContextSize'] ?? false,
      avatarStyle: json['avatarStyle'] ?? 'gradient',
      showFlavorIcon: json['showFlavorIcon'] ?? true,
    );
  }

  DisplaySettings copyWith({
    bool? compactView,
    bool? inlineToolCalls,
    bool? expandTodoList,
    bool? showLineNumbers,
    bool? autoWrap,
    bool? alwaysShowContextSize,
    String? avatarStyle,
    bool? showFlavorIcon,
  }) {
    return DisplaySettings(
      compactView: compactView ?? this.compactView,
      inlineToolCalls: inlineToolCalls ?? this.inlineToolCalls,
      expandTodoList: expandTodoList ?? this.expandTodoList,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      autoWrap: autoWrap ?? this.autoWrap,
      alwaysShowContextSize: alwaysShowContextSize ?? this.alwaysShowContextSize,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      showFlavorIcon: showFlavorIcon ?? this.showFlavorIcon,
    );
  }
}
