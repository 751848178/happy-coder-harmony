part of 'new_session_flow_screen.dart';

List<SessionModeOption> _sessionFlowPermissionOptions(
  _NewSessionFlowScreenState state, {
  String? agent,
}) {
  return newSessionPermissionOptionsForAgent(agent ?? state._selectedAgent);
}

List<SessionModeOption> _sessionFlowModelOptions(
  _NewSessionFlowScreenState state, {
  String? agent,
}) {
  return newSessionModelOptionsForAgent(agent ?? state._selectedAgent);
}

String _defaultSessionFlowModeKey(
  List<SessionModeOption> options,
  String fallback,
) {
  if (options.isEmpty) {
    return fallback;
  }
  return options.first.key;
}

void _syncSessionFlowModeSelections(
  _NewSessionFlowScreenState state, {
  String? agent,
  String? preferredPermissionMode,
  String? preferredModelMode,
}) {
  final resolvedAgent = agent ?? state._selectedAgent;
  final permissionOptions = _sessionFlowPermissionOptions(
    state,
    agent: resolvedAgent,
  );
  final modelOptions = _sessionFlowModelOptions(
    state,
    agent: resolvedAgent,
  );

  state._permissionMode = resolveModeSelection(
    preferred: preferredPermissionMode ?? state._permissionMode,
    options: permissionOptions,
    fallback: _defaultSessionFlowModeKey(
      permissionOptions,
      defaultPermissionModeForAgent(resolvedAgent),
    ),
  );
  state._modelMode = resolveListedModeSelection(
    preferred: preferredModelMode ?? state._modelMode,
    options: modelOptions,
    fallback: _defaultSessionFlowModeKey(
      modelOptions,
      defaultModelModeForAgent(resolvedAgent),
    ),
  );
}

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
