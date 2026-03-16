import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'session_type_selector_chip.dart';
part 'session_type_selector_models.dart';
part 'session_type_selector_selector.dart';
part 'session_type_selector_tiles.dart';

/// Session type
enum SessionType {
  code,
  chat,
  writing,
  debug,
  review,
  translate,
}

/// Session Type Selector Widget
///
/// Allows users to select a session type
class SessionTypeSelector extends StatelessWidget {
  const SessionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.grid = false,
    this.compact = false,
    this.showDescription = true,
  });

  final SessionType selectedType;
  final ValueChanged<SessionType> onTypeChanged;
  final bool grid;
  final bool compact;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    if (grid) return _buildGridSelector();
    if (compact) return _buildCompactSelector();
    return _buildListSelector();
  }
}
