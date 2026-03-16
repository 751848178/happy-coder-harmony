part of 'display_settings.dart';

class _ShowLineNumbersOption extends StatelessWidget {
  const _ShowLineNumbersOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: showLineNumbersProvider,
      title: '显示行号',
      subtitle: '在代码差异视图中显示行号',
      icon: Icons.format_list_numbered,
    );
  }
}

class _AutoWrapOption extends StatelessWidget {
  const _AutoWrapOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: autoWrapProvider,
      title: '自动换行',
      subtitle: '长代码行自动换行显示',
      icon: Icons.wrap_text,
    );
  }
}

class _AlwaysShowContextSizeOption extends StatelessWidget {
  const _AlwaysShowContextSizeOption();

  @override
  Widget build(BuildContext context) {
    return _DisplayToggleOption(
      provider: alwaysShowContextSizeProvider,
      title: '始终显示上下文大小',
      subtitle: '在所有会话中显示上下文使用情况',
      icon: Icons.data_usage,
    );
  }
}
