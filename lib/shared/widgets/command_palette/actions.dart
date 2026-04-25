part of 'command_palette.dart';

void _syncVisibility(
  CommandPalette oldWidget,
  _CommandPaletteState state,
) {
  if (state.widget.visible && !oldWidget.visible) {
    state._searchController.clear();
    state._filteredCommands = state.widget.commands;
    state._selectedIndex = 0;
    state._selectedCommand = null;
    state._focusNode.requestFocus();
    return;
  }
  if (!state.widget.visible && oldWidget.visible) {
    state._focusNode.unfocus();
  }
}

void _handleSearchChanged(_CommandPaletteState state) {
  final query = state._searchController.text.toLowerCase().trim();
  state._updateView(() {
    state._filteredCommands = _filterCommands(state.widget.commands, query);
    state._selectedIndex = 0;
  });
}

List<CommandItem> _filterCommands(List<CommandItem> commands, String query) {
  if (query.isEmpty) {
    return commands;
  }
  final results = <CommandItem>[];
  for (final command in commands) {
    if (_matchesCommand(command, query)) {
      results.add(command);
    }
    for (final subcommand in command.subcommands ?? const <CommandItem>[]) {
      if (_matchesCommand(subcommand, query) &&
          !results.any((candidate) => candidate.id == command.id)) {
        results.add(command);
      }
    }
  }
  return results;
}

bool _matchesCommand(CommandItem command, String query) {
  if (query.isEmpty) {
    return true;
  }
  final labelMatch = command.label.toLowerCase().contains(query);
  final keywordMatch =
      command.keywords.any((keyword) => keyword.toLowerCase().contains(query));
  final descriptionMatch = command.description.toLowerCase().contains(query);
  return labelMatch || keywordMatch || descriptionMatch;
}

void _selectPaletteCommand(_CommandPaletteState state, CommandItem command) {
  if ((command.subcommands ?? const <CommandItem>[]).isNotEmpty) {
    state._updateView(() {
      state._selectedCommand = command;
      state._filteredCommands = command.subcommands!;
      state._selectedIndex = 0;
      state._searchController.clear();
    });
    return;
  }
  command.action?.call();
  state.widget.onCommandSelected?.call(command);
  _closePalette(state);
}

void _goBackInPalette(_CommandPaletteState state) {
  if (state._selectedCommand == null) {
    _closePalette(state);
    return;
  }
  state._updateView(() {
    state._selectedCommand = null;
    state._filteredCommands = state.widget.commands;
    state._selectedIndex = 0;
  });
}

void _closePalette(_CommandPaletteState state) {
  state._searchController.clear();
  state.widget.onClose?.call();
}

void _handlePaletteKeyDown(_CommandPaletteState state, KeyEvent event) {
  if (event is! KeyDownEvent) {
    return;
  }
  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.escape) {
    _closePalette(state);
  } else if (key == LogicalKeyboardKey.arrowDown) {
    _movePaletteSelection(state, 1);
  } else if (key == LogicalKeyboardKey.arrowUp) {
    _movePaletteSelection(state, -1);
  } else if (key == LogicalKeyboardKey.enter) {
    final selected = _selectedCommandAtIndex(state);
    if (selected != null) {
      _selectPaletteCommand(state, selected);
    }
  } else if (key == LogicalKeyboardKey.backspace &&
      state._searchController.text.isEmpty &&
      state._selectedCommand != null) {
    _goBackInPalette(state);
  }
}

void _movePaletteSelection(_CommandPaletteState state, int delta) {
  if (state._filteredCommands.isEmpty) {
    return;
  }
  state._updateView(() {
    state._selectedIndex =
        (state._selectedIndex + delta) % state._filteredCommands.length;
    if (state._selectedIndex < 0) {
      state._selectedIndex += state._filteredCommands.length;
    }
  });
  _scrollPaletteToSelected(state);
}

void _scrollPaletteToSelected(_CommandPaletteState state) {
  if (!state._scrollController.hasClients || state._filteredCommands.isEmpty) {
    return;
  }
  const itemHeight = 64.0;
  final targetOffset = state._selectedIndex * itemHeight -
      state._scrollController.position.viewportDimension / 2 +
      itemHeight / 2;
  state._scrollController.animateTo(
    targetOffset.clamp(0.0, state._scrollController.position.maxScrollExtent),
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
  );
}

CommandItem? _selectedCommandAtIndex(_CommandPaletteState state) {
  if (state._selectedIndex < 0 ||
      state._selectedIndex >= state._filteredCommands.length) {
    return null;
  }
  return state._filteredCommands[state._selectedIndex];
}
