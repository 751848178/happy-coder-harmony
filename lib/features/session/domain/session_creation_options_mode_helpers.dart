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
  for (final key in preferredKeys) {
    final normalizedKey = resolveModeKey([key]);
    if (normalizedKey == null) {
      continue;
    }
    final option = findModeOptionByKey(options, normalizedKey);
    if (option != null) {
      return option;
    }
    return SessionModeOption(
      key: normalizedKey,
      label: normalizedKey,
    );
  }
  if (options.isEmpty) {
    return null;
  }
  return options.first;
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

List<Session> _filterSessionsByAgent(
  Iterable<Session> sessions,
  String? agent,
) {
  final normalizedAgent = normalizeSessionAgent(agent);
  return sessions.where((session) {
    final flavor = normalizeSessionAgent(
      session.metadata?['flavor']?.toString(),
    );
    return flavor == normalizedAgent;
  }).toList(growable: false);
}

Map<String, dynamic>? _firstModeMetadataSource(
  Iterable<List<Session>> sessionGroups,
) {
  for (final sessions in sessionGroups) {
    for (final session in sessions) {
      final metadata = session.metadata;
      if (metadata == null) {
        continue;
      }
      final hasModels = _mapModeOptions(metadata['models']).isNotEmpty;
      final hasOperatingModes =
          _mapModeOptions(metadata['operatingModes']).isNotEmpty;
      if (hasModels || hasOperatingModes) {
        return metadata;
      }
    }
  }
  return null;
}

Map<String, dynamic>? _firstNonEmptyMetadata(
  Iterable<List<Session>> sessionGroups,
) {
  for (final sessions in sessionGroups) {
    for (final session in sessions) {
      final metadata = session.metadata;
      if (metadata != null && metadata.isNotEmpty) {
        return metadata;
      }
    }
  }
  return null;
}

Map<String, dynamic>? _resolveMachineModeMetadata(
  Map<String, dynamic>? metadata, {
  required String agent,
}) {
  if (metadata == null || metadata.isEmpty) {
    return null;
  }
  if (_mapContainsModeMetadata(metadata)) {
    return metadata;
  }

  for (final key in const <String>['agents', 'flavors', 'providers']) {
    final nested = _asModeMetadataMap(metadata[key]);
    if (nested == null || nested.isEmpty) {
      continue;
    }
    final directMatch = _asModeMetadataMap(nested[agent]);
    if (directMatch != null && _mapContainsModeMetadata(directMatch)) {
      return directMatch;
    }
    for (final entry in nested.entries) {
      if (normalizeSessionAgent(entry.key) != agent) {
        continue;
      }
      final matched = _asModeMetadataMap(entry.value);
      if (matched != null && _mapContainsModeMetadata(matched)) {
        return matched;
      }
    }
  }

  return null;
}

Map<String, dynamic>? _asModeMetadataMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry),
    );
  }
  return null;
}

bool _mapContainsModeMetadata(Map<String, dynamic>? metadata) {
  if (metadata == null || metadata.isEmpty) {
    return false;
  }
  return _mapModeOptions(metadata['models']).isNotEmpty ||
      _mapModeOptions(metadata['operatingModes']).isNotEmpty;
}
