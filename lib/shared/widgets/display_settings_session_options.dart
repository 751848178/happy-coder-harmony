part of 'display_settings.dart';

class _CompactViewOption extends StatelessWidget {
  const _CompactViewOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: compactViewProvider,
      title: '紧凑会话视图',
      subtitle: '在会话列表中使用更紧凑的布局',
      icon: Icons.view_list,
    );
  }
}

class _InlineToolCallsOption extends StatelessWidget {
  const _InlineToolCallsOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: inlineToolCallsProvider,
      title: '内联工具调用',
      subtitle: '在聊天中内联显示工具调用结果',
      icon: Icons.integration_instructions,
    );
  }
}

class _ExpandTodoListOption extends StatelessWidget {
  const _ExpandTodoListOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: expandTodoListProvider,
      title: '展开 Todo 列表',
      subtitle: '默认展开聊天中的待办事项',
      icon: Icons.playlist_add_check,
    );
  }
}
