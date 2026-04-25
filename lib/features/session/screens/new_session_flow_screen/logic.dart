part of 'new_session_flow_screen.dart';

List<SessionModeOption> _sessionFlowPermissionOptions(
  _NewSessionFlowScreenState state, {
  String? agent,
  String? machineId,
}) {
  final resolvedAgent = agent ?? state._selectedAgent;
  return newSessionPermissionOptionsForAgent(
    resolvedAgent,
  );
}

List<SessionModeOption> _sessionFlowModelOptions(
  _NewSessionFlowScreenState state, {
  String? agent,
  String? machineId,
}) {
  final resolvedAgent = agent ?? state._selectedAgent;
  final resolvedMachineId = machineId ?? state._selectedMachineId;
  // Fetch machine metadata which may contain PC-provided model options
  dynamic metadataOptions;
  if (resolvedMachineId != null) {
    final notifier = state.ref.read(sessionStateProvider.notifier);
    final machine =
        notifier.machines.where((m) => m.id == resolvedMachineId).firstOrNull;
    metadataOptions = machine?.metadata?['operatingModes']?['models'];
  }
  return newSessionModelOptionsForAgent(
    resolvedAgent,
    metadataOptions: metadataOptions,
  );
}

String _resolveSessionFlowModelMode(
  List<SessionModeOption> options, {
  required String? preferred,
  required String fallback,
}) {
  final normalizedPreferred = resolveModeKey([preferred]);
  if (normalizedPreferred != null) {
    for (final option in options) {
      if (option.key == normalizedPreferred) {
        return option.key;
      }
    }
    if (options.isEmpty) {
      return normalizedPreferred;
    }
  }
  if (options.isNotEmpty) {
    return options.first.key;
  }
  return fallback;
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
  String? machineId,
  String? preferredPermissionMode,
  String? preferredModelMode,
}) {
  final resolvedAgent = agent ?? state._selectedAgent;
  final resolvedMachineId = machineId ?? state._selectedMachineId;
  final permissionOptions = _sessionFlowPermissionOptions(
    state,
    agent: resolvedAgent,
    machineId: resolvedMachineId,
  );
  final modelOptions = _sessionFlowModelOptions(
    state,
    agent: resolvedAgent,
    machineId: resolvedMachineId,
  );

  state._permissionMode = resolveModeSelection(
    preferred: preferredPermissionMode ?? state._permissionMode,
    options: permissionOptions,
    fallback: _defaultSessionFlowModeKey(
      permissionOptions,
      defaultPermissionModeForAgent(resolvedAgent),
    ),
  );
  state._modelMode = _resolveSessionFlowModelMode(
    modelOptions,
    preferred: preferredModelMode ?? state._modelMode,
    fallback: defaultModelModeForAgent(resolvedAgent),
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
