part of 'home_screen.dart';

List<_HomeMachineFilterOption> _buildHomeMachineFilterOptions({
  required List<Machine> machines,
  required List<Session> sessions,
}) {
  final countsByMachineId = <String, int>{};
  final recentSessionByMachineId = <String, Session>{};
  var unknownCount = 0;

  for (final session in sessions) {
    final machineId = _homeSessionMachineId(session);
    if (machineId == null) {
      unknownCount++;
      continue;
    }
    countsByMachineId[machineId] = (countsByMachineId[machineId] ?? 0) + 1;
    final previous = recentSessionByMachineId[machineId];
    if (previous == null || session.updatedAt.isAfter(previous.updatedAt)) {
      recentSessionByMachineId[machineId] = session;
    }
  }

  final options = <_HomeMachineFilterOption>[];
  final seenIds = <String>{};
  final sortedMachines = List<Machine>.from(machines)
    ..sort((a, b) {
      final activeCompare = (b.active ? 1 : 0).compareTo(a.active ? 1 : 0);
      if (activeCompare != 0) {
        return activeCompare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  for (final machine in sortedMachines) {
    if (!seenIds.add(machine.id)) {
      continue;
    }
    options.add(
      _HomeMachineFilterOption(
        id: machine.id,
        label: machine.name,
        subtitle: machine.platform ?? '设备',
        sessionCount: countsByMachineId[machine.id] ?? 0,
        isOnline: machine.active,
      ),
    );
  }

  for (final entry in recentSessionByMachineId.entries) {
    if (!seenIds.add(entry.key)) {
      continue;
    }
    final session = entry.value;
    options.add(
      _HomeMachineFilterOption(
        id: entry.key,
        label: session.metadata?['host']?.toString() ?? entry.key,
        subtitle: session.path ?? '来自最近会话',
        sessionCount: countsByMachineId[entry.key] ?? 0,
      ),
    );
  }

  if (unknownCount > 0) {
    options.add(
      const _HomeMachineFilterOption(
        id: SessionsScreen.unknownMachineFilterId,
        label: '未知设备',
        subtitle: '没有 machineId 的历史会话',
        sessionCount: 0,
        isUnknown: true,
      ),
    );
    options[options.length - 1] = _HomeMachineFilterOption(
      id: SessionsScreen.unknownMachineFilterId,
      label: '未知设备',
      subtitle: '没有 machineId 的历史会话',
      sessionCount: unknownCount,
      isUnknown: true,
    );
  }

  return options;
}

String? _effectiveHomeSelectedMachineId(
  _HomeScreenState state,
  List<_HomeMachineFilterOption> options,
) {
  final selectedMachineId = state._selectedMachineId;
  if (selectedMachineId == null) {
    return null;
  }
  if (options.any((option) => option.id == selectedMachineId)) {
    return selectedMachineId;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!state.mounted || state._selectedMachineId != selectedMachineId) {
      return;
    }
    state._setSelectedMachineId(null);
  });
  return null;
}

String? _homeSessionMachineId(Session session) {
  final machineId = session.metadata?['machineId']?.toString();
  if (machineId == null || machineId.trim().isEmpty) {
    return null;
  }
  return machineId.trim();
}

bool _matchesHomeSelectedMachine(Session session, String? selectedMachineId) {
  if (selectedMachineId == null) {
    return true;
  }
  final machineId = _homeSessionMachineId(session);
  if (selectedMachineId == SessionsScreen.unknownMachineFilterId) {
    return machineId == null;
  }
  return machineId == selectedMachineId;
}
