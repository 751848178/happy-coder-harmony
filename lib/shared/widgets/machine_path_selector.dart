import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'machine_path_selector_controls.dart';
part 'machine_path_selector_chips.dart';
part 'machine_path_selector_models.dart';
part 'machine_path_selector_quick_selectors.dart';
part 'machine_path_selector_sections.dart';

/// Machine and Path Selector Widget
///
/// Allows users to select a machine and path for sessions
class MachinePathSelector extends StatefulWidget {
  const MachinePathSelector({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.onMachineChanged,
    this.onPathChanged,
    this.onSelectionConfirmed,
    this.showRecent = true,
    this.showPathInput = true,
  });

  final String? initialMachineId;
  final String? initialPath;
  final ValueChanged<MachineInfo>? onMachineChanged;
  final ValueChanged<String>? onPathChanged;
  final VoidCallback? onSelectionConfirmed;
  final bool showRecent;
  final bool showPathInput;

  @override
  State<MachinePathSelector> createState() => _MachinePathSelectorState();
}

class _MachinePathSelectorState extends State<MachinePathSelector> {
  MachineInfo? _selectedMachine;
  String? _selectedPath;
  final TextEditingController _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMachine = widget.initialMachineId != null
        ? BuiltInMachines.byId(widget.initialMachineId!)
        : BuiltInMachines.all.first;
    _selectedPath = widget.initialPath;
    if (widget.initialPath != null) {
      _pathController.text = widget.initialPath!;
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _selectMachine(MachineInfo machine) {
    setState(() => _selectedMachine = machine);
    widget.onMachineChanged?.call(machine);
  }

  void _selectPath(PathInfo path) {
    setState(() {
      _selectedPath = path.path;
      _pathController.text = path.path;
    });
    widget.onPathChanged?.call(path.path);
  }

  void _onPathInputChanged(String value) {
    setState(() => _selectedPath = value.isEmpty ? null : value);
    widget.onPathChanged?.call(value.isEmpty ? '/' : value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMachineSelector(),
          const SizedBox(height: 20),
          _buildPathSelector(),
          if (widget.onSelectionConfirmed != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedMachine != null && _selectedPath != null
                    ? widget.onSelectionConfirmed
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('确认选择'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
