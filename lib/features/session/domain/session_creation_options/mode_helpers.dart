part of 'session_creation_options.dart';

Map<String, dynamic>? resolveModeMetadataForSessions(
  Iterable<Session> sessions, {
  required String? machineId,
  required String? agent,
}) {
  final sortedSessions = sessions.toList(growable: false)
    ..sort(compareSessionsByRecency);
  final matchingMachineSessions = machineId == null || machineId.trim().isEmpty
      ? sortedSessions
      : sortedSessions.where((session) {
          return session.metadata?['machineId']?.toString() == machineId;
        }).toList(growable: false);
  final matchingFlavorSessions = _filterSessionsByAgent(
    matchingMachineSessions,
    agent,
  );
  final globalFlavorSessions = _filterSessionsByAgent(
    sortedSessions,
    agent,
  );

  return _firstModeMetadataSource([
        matchingFlavorSessions,
        matchingMachineSessions,
        globalFlavorSessions,
        sortedSessions,
      ]) ??
      _firstNonEmptyMetadata([
        matchingFlavorSessions,
        matchingMachineSessions,
        globalFlavorSessions,
        sortedSessions,
      ]);
}

Map<String, dynamic>? resolveModeMetadataForMachines(
  Iterable<Machine> machines, {
  required String? machineId,
  required String? agent,
}) {
  final normalizedMachineId = machineId?.trim();
  final normalizedAgent = normalizeSessionAgent(agent);
  final matchingMachines =
      (normalizedMachineId == null || normalizedMachineId.isEmpty)
          ? machines
          : machines.where((machine) => machine.id == normalizedMachineId);

  for (final machine in matchingMachines) {
    final metadata = _resolveMachineModeMetadata(
      machine.metadata,
      agent: normalizedAgent,
    );
    if (metadata != null) {
      return metadata;
    }
  }
  return null;
}

Map<String, dynamic>? resolveAvailableModeMetadata({
  Map<String, dynamic>? preferredMetadata,
  required Iterable<Session> sessions,
  required Iterable<Machine> machines,
  required String? machineId,
  required String? agent,
}) {
  final directMetadata = _resolveDirectModeMetadata(
    preferredMetadata,
    agent: agent,
  );
  if (directMetadata != null) {
    return directMetadata;
  }

  return resolveModeMetadataForSessions(
        sessions,
        machineId: machineId,
        agent: agent,
      ) ??
      resolveModeMetadataForMachines(
        machines,
        machineId: machineId,
        agent: agent,
      );
}

String? resolveModeKey(List<String?> candidates) {
  for (final candidate in candidates) {
    final normalized = candidate?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String? resolveLocalModeValue({
  String? preferredValue,
  String? explicitValue,
  String? metadataValue,
}) {
  return resolveModeKey([
    preferredValue,
    explicitValue,
    metadataValue,
  ]);
}

String? resolveRemoteModeValue({
  String? metadataValue,
  String? explicitValue,
  String? preferredValue,
}) {
  return resolveModeKey([
    metadataValue,
    explicitValue,
    preferredValue,
  ]);
}

String? resolveNonDefaultModeValue(List<String?> candidates) {
  final normalized = resolveModeKey(candidates);
  if (normalized == null || normalized == 'default') {
    return null;
  }
  return normalized;
}

String defaultPermissionModeForMetadata(
  Map<String, dynamic>? metadata, {
  String? fallbackAgent,
}) {
  final sandbox = _asModeMetadataMap(metadata?['sandbox']);
  final sandboxEnabled = sandbox?['enabled'] == true;
  if (sandboxEnabled) {
    return 'bypassPermissions';
  }
  return defaultPermissionModeForAgent(
    metadata?['flavor']?.toString() ?? fallbackAgent,
  );
}

String resolveSessionPermissionMode({
  required Map<String, dynamic>? metadata,
  String? localValue,
  String? persistedValue,
  String? explicitValue,
  String? metadataValue,
  String? fallbackAgent,
}) {
  final persistedChoice = resolveModeKey([persistedValue]);
  if (persistedChoice != null) {
    return persistedChoice;
  }

  final localOverride = resolveNonDefaultModeValue([localValue]);
  if (localOverride != null) {
    return localOverride;
  }

  return resolveRemoteModeValue(
        metadataValue: metadataValue,
        explicitValue: explicitValue,
      ) ??
      defaultPermissionModeForMetadata(
        metadata,
        fallbackAgent: fallbackAgent,
      );
}

String resolveSessionModelMode({
  required Map<String, dynamic>? metadata,
  String? localValue,
  String? persistedValue,
  String? explicitValue,
  String? metadataValue,
  String? fallbackAgent,
}) {
  final persistedChoice = resolveNonDefaultModeValue([persistedValue]);
  if (persistedChoice != null) {
    return persistedChoice;
  }

  final localOverride = resolveNonDefaultModeValue([localValue]);
  if (localOverride != null) {
    return localOverride;
  }

  return resolveRemoteModeValue(
        metadataValue: metadataValue,
        explicitValue: explicitValue,
      ) ??
      defaultModelModeForAgent(
        metadata?['flavor']?.toString() ?? fallbackAgent,
      );
}

SessionModeOption? findModeOptionByKey(
  List<SessionModeOption> options,
  String? key,
) {
  final normalized = resolveModeKey([key]);
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  for (final option in options) {
    if (option.key == normalized) {
      return option;
    }
  }
  return null;
}

SessionModeOption? findPreferredListedModeOption(
  List<SessionModeOption> options,
  List<String?> preferredKeys,
) {
  for (final key in preferredKeys) {
    final option = findModeOptionByKey(options, key);
    if (option != null) {
      return option;
    }
  }
  return null;
}

SessionModeOption? resolveCurrentModeOption(
  List<SessionModeOption> options,
  List<String?> preferredKeys,
) {
  return findPreferredListedModeOption(options, preferredKeys);
}

String resolveModeSelection({
  required String? preferred,
  required List<SessionModeOption> options,
  required String fallback,
}) {
  final normalizedPreferred = resolveModeKey([preferred]);
  if (normalizedPreferred != null) {
    for (final option in options) {
      if (option.key == normalizedPreferred) {
        return option.key;
      }
    }
    return normalizedPreferred;
  }
  return fallback;
}

String resolveListedModeSelection({
  required String? preferred,
  required List<SessionModeOption> options,
  required String fallback,
}) {
  final normalizedPreferred = resolveModeKey([preferred]);
  if (normalizedPreferred != null) {
    for (final option in options) {
      if (option.key == normalizedPreferred) {
        return option.key;
      }
    }
  }
  return fallback;
}
