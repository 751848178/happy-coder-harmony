part of 'session_creation_options.dart';

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

Map<String, dynamic>? _resolveDirectModeMetadata(
  Map<String, dynamic>? metadata, {
  required String? agent,
}) {
  if (metadata == null || metadata.isEmpty) {
    return null;
  }
  if (_mapContainsModeMetadata(metadata)) {
    return metadata;
  }
  return _resolveMachineModeMetadata(
    metadata,
    agent: normalizeSessionAgent(agent),
  );
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
