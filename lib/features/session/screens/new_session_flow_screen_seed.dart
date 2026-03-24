part of 'new_session_flow_screen.dart';

void _seedSessionFlowInitialState(
  _NewSessionFlowScreenState state, {
  required SettingsState settings,
  required List<_MachineOption> machines,
  required List<Session> sessions,
}) {
  final explicitAgent = state.widget.initialAgent != null &&
          state.widget.initialAgent!.trim().isNotEmpty
      ? normalizeSessionAgent(state.widget.initialAgent!)
      : null;
  final initialAgent =
      explicitAgent ?? normalizeSessionAgent(settings.lastUsedAgent);
  final initialPermission = resolveModeSelection(
    preferred:
        state.widget.initialPermissionMode ?? settings.lastUsedPermissionMode,
    options: permissionOptionsForAgent(initialAgent),
    fallback: defaultPermissionModeForAgent(initialAgent),
  );
  final initialMachineId = state._selectedMachineId ??
      (machines.isNotEmpty ? machines.first.id : null);

  state._updateView(() {
    state._selectedAgent = initialAgent;
    state._permissionMode = initialPermission;
    state._selectedMachineId = initialMachineId;
    if (state._pathController.text.trim().isEmpty && initialMachineId != null) {
      state._pathController.text = _defaultSessionFlowPathForMachine(
              initialMachineId, sessions, machines) ??
          '';
    }
    state._seededInitialState = true;
  });
}

List<_MachineOption> _collectSessionFlowMachineOptions(
  _NewSessionFlowScreenState state,
  SessionServiceNotifier notifier,
) {
  final options = <_MachineOption>[];
  final seenIds = <String>{};

  for (final machine in notifier.machines) {
    if (!seenIds.add(machine.id)) {
      continue;
    }
    options.add(
      _MachineOption(
        id: machine.id,
        title: machine.name,
        subtitle: [
          if ((machine.metadata?['host']?.toString() ?? '').isNotEmpty)
            machine.metadata!['host'].toString(),
          if ((machine.platform ?? '').isNotEmpty) machine.platform!,
          machine.active ? '在线' : '离线',
        ].join(' • '),
        host: machine.metadata?['host']?.toString() ?? machine.name,
        homeDir: machine.metadata?['homeDir']?.toString(),
        isOnline: machine.active,
      ),
    );
  }

  for (final session in notifier.sessions) {
    final machineId = session.metadata?['machineId']?.toString();
    if (machineId == null || machineId.isEmpty || !seenIds.add(machineId)) {
      continue;
    }
    options.add(
      _MachineOption(
        id: machineId,
        title: session.metadata?['host']?.toString() ?? machineId,
        subtitle: [
          if ((session.path ?? '').isNotEmpty)
            _compactSessionFlowPath(session.path!),
          session.active ? '在线' : '离线',
        ].join(' • '),
        host: session.metadata?['host']?.toString() ?? machineId,
        homeDir: session.metadata?['homeDir']?.toString(),
        isOnline: session.active,
      ),
    );
  }
  return options;
}
