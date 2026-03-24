import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/settings_service.dart' show SettingsState;
import '../../../core/theme/app_theme.dart';
import '../domain/session_creation_options.dart';

part 'new_session_flow_screen_content.dart';
part 'new_session_flow_screen_logic.dart';
part 'new_session_flow_screen_seed.dart';
part 'new_session_flow_screen_agent_logic.dart';
part 'new_session_flow_screen_pickers.dart';
part 'new_session_flow_screen_create.dart';
part 'new_session_flow_screen_composer_widgets.dart';
part 'new_session_flow_screen_notice_widgets.dart';
part 'new_session_flow_screen_action_widgets.dart';
part 'new_session_flow_screen_sheet_widgets.dart';
part 'new_session_flow_screen_models.dart';

class NewSessionFlowScreen extends ConsumerStatefulWidget {
  const NewSessionFlowScreen({
    super.key,
    this.initialMachineId,
    this.initialPath,
    this.initialAgent,
    this.initialPermissionMode,
    this.initialModelMode,
  });

  final String? initialMachineId;
  final String? initialPath;
  final String? initialAgent;
  final String? initialPermissionMode;
  final String? initialModelMode;

  @override
  ConsumerState<NewSessionFlowScreen> createState() =>
      _NewSessionFlowScreenState();
}

class _NewSessionFlowScreenState extends ConsumerState<NewSessionFlowScreen> {
  static const double _maxContentWidth = 720;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  String? _selectedMachineId;
  String _selectedAgent = 'claude';
  String _permissionMode = defaultPermissionModeForAgent('claude');
  bool _isCreating = false;
  bool _seededInitialState = false;

  @override
  void initState() {
    super.initState();
    _selectedMachineId = widget.initialMachineId;
    if (widget.initialPath != null && widget.initialPath!.trim().isNotEmpty) {
      _pathController.text = widget.initialPath!.trim();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  void _cycleAgent() => _cycleSessionFlowAgent(this);

  Future<void> _pickMachine() => _pickSessionFlowMachine(this);

  Future<void> _pickPath() => _pickSessionFlowPath(this);

  Future<void> _showSettingsSheet() => _showSessionFlowSettingsSheet(this);

  Future<void> _createSession(_MachineOption? machine) =>
      _createSessionFlowSession(this, machine);

  void _closeScreen() => _closeSessionFlowScreen(this);

  @override
  Widget build(BuildContext context) => _buildNewSessionFlowScreen(this);
}
