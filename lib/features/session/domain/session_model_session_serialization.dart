part of 'session_models.dart';

Map<String, dynamic> _sessionToJson(Session session) {
  return {
    'id': session.id,
    if (session.seq != null) 'seq': session.seq,
    'title': session.title,
    'messages': session.messages,
    'createdAt': session.createdAt.toIso8601String(),
    'updatedAt': session.updatedAt.toIso8601String(),
    'active': session.active,
    if (session.activeAt != null)
      'activeAt': session.activeAt!.toIso8601String(),
    if (session.tag != null) 'tag': session.tag,
    if (session.path != null) 'path': session.path,
    if (session.metadata != null) 'metadata': session.metadata,
    if (session.metadataVersion != null)
      'metadataVersion': session.metadataVersion,
    if (session.permissionMode != null)
      'permissionMode': session.permissionMode,
    if (session.modelMode != null) 'modelMode': session.modelMode,
    if (session.draft != null) 'draft': session.draft,
    if (session.agentState != null) 'agentState': session.agentState,
    if (session.agentStateVersion != null)
      'agentStateVersion': session.agentStateVersion,
    if (session.todos != null)
      'todos': session.todos!.map((todo) => todo.toJson()).toList(),
    if (session.presence != null) 'presence': session.presence!.toJson(),
    if (session.thinking != null) 'thinking': session.thinking,
    if (session.thinkingAt != null)
      'thinkingAt': session.thinkingAt!.toIso8601String(),
    if (session.latestUsage != null)
      'latestUsage': session.latestUsage!.toJson(),
  };
}

Session _sessionFromJson(Map<String, dynamic> json) {
  final metadata = _asStringMap(
    json['metadata'] ?? json['sessionMetadata'] ?? json['session_metadata'],
  );
  final agentState = _asStringMap(json['agentState'] ?? json['agent_state']);
  final fallbackId = _firstNonEmptyString([
        json['id'],
        json['sessionId'],
        json['session_id'],
        json['sid'],
      ]) ??
      '';
  final metadataPath = _firstNonEmptyString([
    json['path'],
    json['sessionPath'],
    json['session_path'],
    metadata?['path'],
  ]);
  final pathSegments =
      metadataPath?.split('/').where((item) => item.isNotEmpty).toList();
  final title = _firstNonEmptyString([
        json['title'],
        json['name'],
        json['sessionTitle'],
        json['session_title'],
        metadata?['name'],
        metadata?['title'],
      ]) ??
      (pathSegments != null && pathSegments.isNotEmpty
          ? pathSegments.last
          : null) ??
      _firstNonEmptyString(
          [json['tag'], json['sessionTag'], json['session_tag']]) ??
      (fallbackId.isNotEmpty
          ? '会话 ${fallbackId.length > 8 ? fallbackId.substring(0, 8) : fallbackId}'
          : '未命名会话');
  final latestUsageJson = _asStringMap(
    json['latestUsage'] ?? json['latest_usage'],
  );

  return Session(
    id: fallbackId,
    seq: _parseInt(json['seq']),
    title: title,
    messages: _asDynamicList(json['messages']),
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ??
        DateTime.now(),
    updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']) ??
        DateTime.now(),
    active: _parseBool(json['active']) ?? true,
    activeAt: _parseDateTime(json['activeAt'] ?? json['active_at']),
    tag: _firstNonEmptyString(
        [json['tag'], json['sessionTag'], json['session_tag']]),
    path: metadataPath,
    metadata: metadata,
    metadataVersion:
        _parseInt(json['metadataVersion'] ?? json['metadata_version']),
    permissionMode: _firstNonEmptyString([
      json['permissionMode'],
      json['permission_mode'],
    ]),
    modelMode: _firstNonEmptyString([json['modelMode'], json['model_mode']]),
    draft: _firstNonEmptyString([json['draft']]),
    agentState: agentState,
    agentStateVersion:
        _parseInt(json['agentStateVersion'] ?? json['agent_state_version']),
    todos: _parseTodos(json['todos']),
    presence: json['presence'] != null
        ? PresenceStatus.fromDynamic(json['presence'])
        : null,
    thinking: _parseBool(json['thinking']),
    thinkingAt: _parseDateTime(json['thinkingAt'] ?? json['thinking_at']),
    latestUsage:
        latestUsageJson != null ? LatestUsage.fromJson(latestUsageJson) : null,
  );
}
