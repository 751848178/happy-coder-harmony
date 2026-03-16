import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'terminal_list_screen_models.dart';
part 'terminal_list_screen_logic.dart';
part 'terminal_list_screen_content.dart';
part 'terminal_list_screen_dialogs.dart';
part 'terminal_list_screen_card.dart';
part 'terminal_list_screen_detail_row.dart';

/// Terminal List Screen
///
/// Manages multiple terminal sessions
class TerminalListScreen extends ConsumerStatefulWidget {
  const TerminalListScreen({super.key});

  @override
  ConsumerState<TerminalListScreen> createState() => _TerminalListScreenState();
}

class _TerminalListScreenState extends ConsumerState<TerminalListScreen> {
  final List<TerminalSession> _sessions = [];
  final _nameController = TextEditingController();
  final _machineController = TextEditingController();
  final _pathController = TextEditingController();

  int get _activeCount =>
      _sessions.where((s) => s.status == TerminalStatus.active).length;
  int get _errorCount =>
      _sessions.where((s) => s.status == TerminalStatus.error).length;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() => _loadTerminalSessions(this);

  void _addSession() => _showAddSessionDialog(this);

  void _connectToSession(TerminalSession session) =>
      _connectTerminalSession(this, session);

  void _disconnectSession(TerminalSession session) =>
      _disconnectTerminalSession(this, session);

  void _deleteSession(String id) => _deleteTerminalSession(this, id);

  void _reconnectSession(TerminalSession session) =>
      _reconnectTerminalSession(this, session);

  void _showSessionDetails(TerminalSession session) =>
      _showTerminalSessionDetails(this, session);

  void _showSnackBar(String message, {required bool isError}) =>
      _showTerminalSnackBar(this, message, isError: isError);

  String _formatTime(DateTime time) => _formatTerminalTime(time);

  void _showDeleteConfirmation(TerminalSession session) =>
      _showDeleteTerminalConfirmation(this, session);

  @override
  Widget build(BuildContext context) => _buildTerminalListScaffold(this);

  @override
  void dispose() {
    _nameController.dispose();
    _machineController.dispose();
    _pathController.dispose();
    super.dispose();
  }
}
