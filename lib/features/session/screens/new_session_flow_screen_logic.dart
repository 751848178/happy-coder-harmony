part of 'new_session_flow_screen.dart';

String _effectiveSessionFlowDirectory(
  _NewSessionFlowScreenState state,
  _MachineOption? machine,
) {
  final manual = state._pathController.text.trim();
  if (manual.isNotEmpty) {
    return manual;
  }
  return machine?.homeDir?.trim() ?? '';
}

String? _defaultSessionFlowPathForMachine(
  String machineId,
  List<Session> sessions,
  List<_MachineOption> machines,
) {
  return _mostRecentSessionFlowPathForMachine(machineId, sessions) ??
      machines
          .where((item) => item.id == machineId)
          .cast<_MachineOption?>()
          .firstWhere((item) => item != null, orElse: () => null)
          ?.homeDir;
}

String? _mostRecentSessionFlowPathForMachine(
  String machineId,
  List<Session> sessions,
) {
  final items = sessions
      .where(
          (session) => session.metadata?['machineId']?.toString() == machineId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final session in items) {
    final path = session.path ?? session.metadata?['path']?.toString() ?? '';
    if (path.isNotEmpty) {
      return path;
    }
  }
  return null;
}
