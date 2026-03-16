import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

part 'command_palette_actions.dart';
part 'command_palette_defaults.dart';
part 'command_palette_models.dart';
part 'command_palette_views.dart';
part 'command_palette_widgets.dart';

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
    _syncVisibility(oldWidget, this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _onSearchChanged() => _handleSearchChanged(this);

  void _selectCommand(CommandItem command) =>
      _selectPaletteCommand(this, command);

  void _goBack() => _goBackInPalette(this);

  void _close() => _closePalette(this);

  void _handleKeyDown(KeyEvent event) => _handlePaletteKeyDown(this, event);

  void _moveSelection(int delta) => _movePaletteSelection(this, delta);

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }
    return Actions(
      actions: _buildCommandPaletteActions(this),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyDown,
        child: _CommandPaletteOverlay(
          visible: widget.visible,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: _commandPaletteDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCommandPaletteSearchBar(this),
                  _buildCommandPaletteList(this),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
