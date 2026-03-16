part of 'command_palette.dart';

final _commandPaletteDecoration = BoxDecoration(
  color: AppTheme.surface,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ],
);

Map<Type, Action<Intent>> _buildCommandPaletteActions(
  _CommandPaletteState state,
) {
  return <Type, Action<Intent>>{
    _EscapeIntent: CallbackAction<_EscapeIntent>(
      onInvoke: (_) => state._close(),
    ),
    _ArrowDownIntent: CallbackAction<_ArrowDownIntent>(
      onInvoke: (_) => state._moveSelection(1),
    ),
    _ArrowUpIntent: CallbackAction<_ArrowUpIntent>(
      onInvoke: (_) => state._moveSelection(-1),
    ),
    _EnterIntent: CallbackAction<_EnterIntent>(
      onInvoke: (_) {
        final selected = _selectedCommandAtIndex(state);
        if (selected != null) {
          state._selectCommand(selected);
        }
        return null;
      },
    ),
  };
}

Widget _buildCommandPaletteSearchBar(_CommandPaletteState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppTheme.neutral200, width: 1),
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: AppTheme.neutral500),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: state._searchController,
            focusNode: state._focusNode,
            decoration: InputDecoration(
              hintText: state.widget.placeholder,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: AppTheme.neutral400),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        if (state._selectedCommand != null)
          TextButton.icon(
            onPressed: state._goBack,
            icon: const Icon(Icons.chevron_left),
            label: const Text('返回'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.neutral600,
            ),
          ),
      ],
    ),
  );
}

Widget _buildCommandPaletteList(_CommandPaletteState state) {
  if (state._filteredCommands.isEmpty) {
    return const SizedBox(
      height: 200,
      child: _EmptyCommandPaletteState(),
    );
  }
  final itemCount =
      state._filteredCommands.length > 8 ? 8 : state._filteredCommands.length;
  return SizedBox(
    height: 64.0 * itemCount + (state._filteredCommands.length > 8 ? 30 : 0),
    child: ListView.builder(
      controller: state._scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final command = state._filteredCommands[index];
        return _CommandItemWidget(
          command: command,
          isSelected: index == state._selectedIndex,
          onTap: () => state._selectCommand(command),
        );
      },
    ),
  );
}

class _EmptyCommandPaletteState extends StatelessWidget {
  const _EmptyCommandPaletteState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search_off, size: 48, color: AppTheme.neutral400),
          SizedBox(height: 16),
          Text(
            '未找到匹配的命令',
            style: TextStyle(fontSize: 14, color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }
}
