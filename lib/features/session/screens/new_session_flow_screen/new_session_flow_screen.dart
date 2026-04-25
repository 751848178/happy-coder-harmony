import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/services/settings_service.dart' show SettingsState;
import '../../../../core/theme/app_theme.dart';
import '../../domain/session_creation_options.dart';
import '../../presentation/session_detail_navigation.dart';
import '../../../socketio/domain/socket_service.dart';

part 'content.dart';
part 'logic.dart';
part 'seed.dart';
part 'agent_logic.dart';
part 'pickers.dart';
part 'create.dart';
part 'composer_widgets.dart';
part 'notice_widgets.dart';
part 'action_widgets.dart';
part 'sheet_widgets.dart';
part 'models.dart';

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
  String _modelMode = defaultModelModeForAgent('claude');
  bool _isCreating = false;
  bool _seededInitialState = false;
  StreamSubscription<SocketEvent>? _socketEventSubscription;
  Timer? _sessionRefreshDebounce;

  @override
  void initState() {
    super.initState();
    _selectedMachineId = widget.initialMachineId;
    if (widget.initialPath != null && widget.initialPath!.trim().isNotEmpty) {
      _pathController.text = widget.initialPath!.trim();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(sessionStateProvider.notifier);
      unawaited(notifier.loadSessions(force: true));
      unawaited(notifier.loadMachines(force: true, allowFailure: true));
    });
    _subscribeToSocketEvents();
  }

  @override
  void dispose() {
    _socketEventSubscription?.cancel();
    _sessionRefreshDebounce?.cancel();
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

  void _subscribeToSocketEvents() {
    final socketNotifier = ref.read(socketStateProvider.notifier);
    _socketEventSubscription = socketNotifier.eventStream.listen((event) {
      event.when(
        connecting: () {},
        connected: (_) => _scheduleRemoteContextRefresh(),
        disconnected: (_) {},
        error: (_) {},
        messageReceived: (_) {},
        reconnecting: (_) => _scheduleRemoteContextRefresh(),
      );
    });
  }

  void _scheduleRemoteContextRefresh() {
    _sessionRefreshDebounce?.cancel();
    _sessionRefreshDebounce = Timer(
      const Duration(milliseconds: 220),
      () {
        final notifier = ref.read(sessionStateProvider.notifier);
        unawaited(notifier.loadSessions(force: true));
        unawaited(notifier.loadMachines(force: true, allowFailure: true));
      },
    );
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
