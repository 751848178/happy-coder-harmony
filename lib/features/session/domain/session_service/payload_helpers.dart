part of 'session_service.dart';

extension SessionServicePayloadHelpers on SessionServiceNotifier {
  List<dynamic> _extractListPayload(
    dynamic response,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    if (response == null) {
      return const [];
    }
    if (response is List<dynamic>) {
      return response;
    }
    final responseMap = _asStringMap(response);
    if (responseMap == null) {
      return const [];
    }
    return _extractListFromMap(responseMap, [key, ...fallbackKeys]);
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    if (value is String && value.isNotEmpty) {
      try {
        return _asStringMap(jsonDecode(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<dynamic> _extractListFromMap(
    Map<String, dynamic>? map,
    List<String> candidateKeys,
  ) {
    if (map == null) {
      return const [];
    }
    for (final candidate in candidateKeys) {
      final value = map[candidate];
      if (value is List<dynamic>) {
        return value;
      }
      if (value is List) {
        return value.toList();
      }
      final nested = _asStringMap(value);
      final nestedList = _extractListFromMap(
        nested,
        const ['items', 'results', 'data', 'sessions', 'messages'],
      );
      if (nestedList.isNotEmpty || _containsListPayloadKey(nested, candidate)) {
        return nestedList;
      }
    }

    for (final fallback in const ['data', 'items', 'results']) {
      if (candidateKeys.contains(fallback)) {
        continue;
      }
      final value = map[fallback];
      if (value is List<dynamic>) {
        return value;
      }
      if (value is List) {
        return value.toList();
      }
      final nested = _asStringMap(value);
      final nestedList = _extractListFromMap(
        nested,
        const ['items', 'results', 'data', 'sessions', 'messages'],
      );
      if (nestedList.isNotEmpty || _containsListPayloadKey(nested, fallback)) {
        return nestedList;
      }
    }
    return const [];
  }

  bool _containsListPayloadKey(
    dynamic response,
    String key, {
    List<String> fallbackKeys = const [],
  }) {
    if (response is List) {
      return true;
    }
    final responseMap = _asStringMap(response);
    if (responseMap == null) {
      return false;
    }
    return _mapContainsListPayloadKey(responseMap, [key, ...fallbackKeys]);
  }

  bool _mapContainsListPayloadKey(
    Map<String, dynamic>? map,
    List<String> candidateKeys,
  ) {
    if (map == null) {
      return false;
    }
    for (final candidate in [...candidateKeys, 'data', 'items', 'results']) {
      if (!map.containsKey(candidate)) {
        continue;
      }
      final value = map[candidate];
      if (value is List) {
        return true;
      }
      final nested = _asStringMap(value);
      if (nested != null &&
          _mapContainsListPayloadKey(
            nested,
            const ['items', 'results', 'data', 'sessions', 'messages'],
          )) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _normalizeSessionPayload(dynamic value) {
    final raw = _asStringMap(value);
    if (raw == null) {
      return null;
    }
    final merged = <String, dynamic>{...raw};
    for (final candidateKey in const ['session', 'item', 'data', 'value']) {
      final nested = _asStringMap(raw[candidateKey]);
      if (nested != null) {
        merged.addAll(nested);
      }
    }
    final id = _extractSessionId(merged);
    if (id == null) {
      return merged;
    }
    return {
      ...merged,
      'id': id,
      'sessionId': merged['sessionId'] ?? merged['session_id'] ?? merged['sid'],
      'createdAt': merged['createdAt'] ?? merged['created_at'],
      'updatedAt': merged['updatedAt'] ?? merged['updated_at'],
      'activeAt': merged['activeAt'] ?? merged['active_at'],
      'metadata': merged['metadata'] ??
          merged['sessionMetadata'] ??
          merged['session_metadata'],
      'metadataVersion':
          merged['metadataVersion'] ?? merged['metadata_version'],
      'agentState': merged['agentState'] ?? merged['agent_state'],
      'agentStateVersion':
          merged['agentStateVersion'] ?? merged['agent_state_version'],
      'dataEncryptionKey':
          merged['dataEncryptionKey'] ?? merged['data_encryption_key'],
      'permissionMode': merged['permissionMode'] ?? merged['permission_mode'],
      'modelMode': merged['modelMode'] ?? merged['model_mode'],
      'thinkingAt': merged['thinkingAt'] ?? merged['thinking_at'],
      'latestUsage': merged['latestUsage'] ?? merged['latest_usage'],
    };
  }

  String? _extractSessionId(dynamic value) {
    final map = _asStringMap(value);
    if (map == null) {
      return null;
    }
    for (final candidate in const ['id', 'sessionId', 'session_id', 'sid']) {
      final raw = map[candidate];
      final id = raw?.toString().trim();
      if (id != null && id.isNotEmpty && id != 'null') {
        return id;
      }
    }
    for (final nestedKey in const ['session', 'item', 'data', 'value']) {
      final nestedId = _extractSessionId(map[nestedKey]);
      if (nestedId != null) {
        return nestedId;
      }
    }
    return null;
  }
}
