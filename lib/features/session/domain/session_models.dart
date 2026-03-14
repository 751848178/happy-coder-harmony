import 'dart:convert';

import 'reducer.dart';

const Object _sessionFieldUnset = Object();

/// 会话模型
class Session {
  final String id;
  final int? seq;
  final String title;
  final List<dynamic> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final DateTime? activeAt;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;
  final int? metadataVersion;
  final String? permissionMode;
  final String? modelMode;
  final String? draft;
  final Map<String, dynamic>? agentState;
  final int? agentStateVersion;
  final List<Todo>? todos;
  // 实时功能字段
  final PresenceStatus? presence;
  final bool? thinking;
  final DateTime? thinkingAt;
  final LatestUsage? latestUsage;

  const Session({
    required this.id,
    this.seq,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.active,
    this.activeAt,
    this.tag,
    this.path,
    this.metadata,
    this.metadataVersion,
    this.permissionMode,
    this.modelMode,
    this.draft,
    this.agentState,
    this.agentStateVersion,
    this.todos,
    this.presence,
    this.thinking,
    this.thinkingAt,
    this.latestUsage,
  });

  Session copyWith({
    String? id,
    int? seq,
    String? title,
    List<dynamic>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    Object? activeAt = _sessionFieldUnset,
    String? tag,
    String? path,
    Map<String, dynamic>? metadata,
    int? metadataVersion,
    String? permissionMode,
    String? modelMode,
    String? draft,
    Map<String, dynamic>? agentState,
    int? agentStateVersion,
    List<Todo>? todos,
    PresenceStatus? presence,
    bool? thinking,
    Object? thinkingAt = _sessionFieldUnset,
    LatestUsage? latestUsage,
  }) {
    return Session(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      activeAt: identical(activeAt, _sessionFieldUnset)
          ? this.activeAt
          : activeAt as DateTime?,
      tag: tag ?? this.tag,
      path: path ?? this.path,
      metadata: metadata ?? this.metadata,
      metadataVersion: metadataVersion ?? this.metadataVersion,
      permissionMode: permissionMode ?? this.permissionMode,
      modelMode: modelMode ?? this.modelMode,
      draft: draft ?? this.draft,
      agentState: agentState ?? this.agentState,
      agentStateVersion: agentStateVersion ?? this.agentStateVersion,
      todos: todos ?? this.todos,
      presence: presence ?? this.presence,
      thinking: thinking ?? this.thinking,
      thinkingAt: identical(thinkingAt, _sessionFieldUnset)
          ? this.thinkingAt
          : thinkingAt as DateTime?,
      latestUsage: latestUsage ?? this.latestUsage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (seq != null) 'seq': seq,
      'title': title,
      'messages': messages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      if (activeAt != null) 'activeAt': activeAt!.toIso8601String(),
      if (tag != null) 'tag': tag,
      if (path != null) 'path': path,
      if (metadata != null) 'metadata': metadata,
      if (metadataVersion != null) 'metadataVersion': metadataVersion,
      if (permissionMode != null) 'permissionMode': permissionMode,
      if (modelMode != null) 'modelMode': modelMode,
      if (draft != null) 'draft': draft,
      if (agentState != null) 'agentState': agentState,
      if (agentStateVersion != null) 'agentStateVersion': agentStateVersion,
      if (todos != null) 'todos': todos!.map((todo) => todo.toJson()).toList(),
      if (presence != null) 'presence': presence!.toJson(),
      if (thinking != null) 'thinking': thinking,
      if (thinkingAt != null) 'thinkingAt': thinkingAt!.toIso8601String(),
      if (latestUsage != null) 'latestUsage': latestUsage!.toJson(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    final metadata = _asStringMap(
      json['metadata'] ?? json['sessionMetadata'] ?? json['session_metadata'],
    );
    final agentState = _asStringMap(
      json['agentState'] ?? json['agent_state'],
    );
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
      tag: _firstNonEmptyString([
        json['tag'],
        json['sessionTag'],
        json['session_tag'],
      ]),
      path: metadataPath,
      metadata: metadata,
      metadataVersion:
          _parseInt(json['metadataVersion'] ?? json['metadata_version']),
      permissionMode: _firstNonEmptyString([
        json['permissionMode'],
        json['permission_mode'],
      ]),
      modelMode: _firstNonEmptyString([
        json['modelMode'],
        json['model_mode'],
      ]),
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
      latestUsage: latestUsageJson != null
          ? LatestUsage.fromJson(latestUsageJson)
          : null,
    );
  }
}

/// 在线状态
class PresenceStatus {
  final String status; // "online" | number (last active timestamp)
  final DateTime? lastActiveAt;
  final List<SessionPresence>? users;

  const PresenceStatus({
    required this.status,
    this.lastActiveAt,
    this.users,
  });

  bool get isOnline => status == 'online';

  bool get isIdle => status != 'online' && lastActiveAt != null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt!.toIso8601String(),
      if (users != null) 'users': users!.map((u) => u.toJson()).toList(),
    };
  }

  factory PresenceStatus.fromJson(Map<String, dynamic> json) {
    final status = _firstNonEmptyString([json['status']]) ?? 'offline';
    final lastActiveAt =
        _parseDateTime(json['lastActiveAt'] ?? json['last_active_at']);
    final users = _asDynamicList(json['users'])
        .map(_asStringMap)
        .whereType<Map<String, dynamic>>()
        .map(SessionPresence.fromJson)
        .toList();

    return PresenceStatus(
      status: status,
      lastActiveAt: lastActiveAt,
      users: users.isEmpty ? null : users,
    );
  }

  factory PresenceStatus.fromDynamic(dynamic value) {
    if (value == null) {
      return PresenceStatus(
        status: 'offline',
        lastActiveAt: null,
      );
    }
    if (value is Map<String, dynamic>) {
      return PresenceStatus.fromJson(value);
    }
    if (value is String) {
      return PresenceStatus(status: value);
    }
    if (value is int) {
      return PresenceStatus(
        status: 'idle',
        lastActiveAt: DateTime.fromMillisecondsSinceEpoch(value),
      );
    }
    return PresenceStatus(status: value.toString());
  }
}

/// 会话用户在线状态
class SessionPresence {
  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const SessionPresence({
    required this.userId,
    required this.userName,
    required this.isOnline,
    this.lastSeenAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'isOnline': isOnline,
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
    };
  }

  factory SessionPresence.fromJson(Map<String, dynamic> json) {
    return SessionPresence(
      userId: _firstNonEmptyString([json['userId'], json['user_id']]) ?? '',
      userName:
          _firstNonEmptyString([json['userName'], json['user_name']]) ?? '',
      isOnline: _parseBool(json['isOnline'] ?? json['is_online']) ?? false,
      lastSeenAt: _parseDateTime(json['lastSeenAt'] ?? json['last_seen_at']),
    );
  }
}

/// 最新使用统计
class LatestUsage {
  final int messageCount;
  final int tokenCount;
  final DateTime timestamp;
  final int? filesAccessed;
  final int? toolsUsed;

  const LatestUsage({
    required this.messageCount,
    required this.tokenCount,
    required this.timestamp,
    this.filesAccessed,
    this.toolsUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageCount': messageCount,
      'tokenCount': tokenCount,
      'timestamp': timestamp.toIso8601String(),
      if (filesAccessed != null) 'filesAccessed': filesAccessed,
      if (toolsUsed != null) 'toolsUsed': toolsUsed,
    };
  }

  factory LatestUsage.fromJson(Map<String, dynamic> json) {
    return LatestUsage(
      messageCount: _parseInt(json['messageCount']) ??
          _parseInt(json['outputTokens']) ??
          _parseInt(json['message_count']) ??
          0,
      tokenCount: _parseInt(json['tokenCount']) ??
          _parseInt(json['contextSize']) ??
          _parseInt(json['inputTokens']) ??
          _parseInt(json['token_count']) ??
          0,
      timestamp: _parseDateTime(json['timestamp']) ?? DateTime.now(),
      filesAccessed:
          _parseInt(json['filesAccessed']) ?? _parseInt(json['cacheRead']),
      toolsUsed:
          _parseInt(json['toolsUsed']) ?? _parseInt(json['cacheCreation']),
    );
  }
}

/// 机器模型
class Machine {
  final String id;
  final int? seq;
  final String name;
  final String? platform;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool active;
  final DateTime? activeAt;
  final Map<String, dynamic>? metadata;
  final int? metadataVersion;

  const Machine({
    required this.id,
    required this.name,
    this.platform,
    required this.createdAt,
    this.seq,
    this.updatedAt,
    this.active = true,
    this.activeAt,
    this.metadata,
    this.metadataVersion,
  });

  Machine copyWith({
    String? id,
    int? seq,
    String? name,
    String? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
    DateTime? activeAt,
    Map<String, dynamic>? metadata,
    int? metadataVersion,
  }) {
    return Machine(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      active: active ?? this.active,
      activeAt: activeAt ?? this.activeAt,
      metadata: metadata ?? this.metadata,
      metadataVersion: metadataVersion ?? this.metadataVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (seq != null) 'seq': seq,
      'name': name,
      if (platform != null) 'platform': platform,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'active': active,
      if (activeAt != null) 'activeAt': activeAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (metadataVersion != null) 'metadataVersion': metadataVersion,
    };
  }

  factory Machine.fromJson(Map<String, dynamic> json) {
    final metadata = _asStringMap(json['metadata']);
    final machineId = _firstNonEmptyString([
          json['id'],
          json['machineId'],
          json['machine_id'],
        ]) ??
        '';
    return Machine(
      id: machineId,
      seq: _parseInt(json['seq']),
      name: _firstNonEmptyString([
            json['name'],
            json['displayName'],
            json['display_name'],
          ]) ??
          metadata?['displayName']?.toString() ??
          metadata?['host']?.toString() ??
          machineId,
      platform: _firstNonEmptyString([
        json['platform'],
        json['os'],
        metadata?['platform'],
      ]),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      active: _parseBool(json['active']) ?? true,
      activeAt: _parseDateTime(json['activeAt'] ?? json['active_at']),
      metadata: metadata,
      metadataVersion:
          _parseInt(json['metadataVersion'] ?? json['metadata_version']),
    );
  }
}

List<dynamic> _asDynamicList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  if (value is List) {
    return value.toList();
  }
  return const <dynamic>[];
}

List<Todo>? _parseTodos(dynamic value) {
  final todos = <Todo>[];
  for (final rawTodo in _asDynamicList(value)) {
    final todoMap = _asStringMap(rawTodo);
    if (todoMap == null) {
      continue;
    }
    try {
      todos.add(
        Todo(
          id: _firstNonEmptyString([todoMap['id']]) ?? '',
          title: _firstNonEmptyString([todoMap['title']]) ?? '',
          description: _firstNonEmptyString([todoMap['description']]),
          completed: _parseBool(todoMap['completed']) ?? false,
          createdAt:
              _parseDateTime(todoMap['createdAt'] ?? todoMap['created_at']),
          completedAt:
              _parseDateTime(todoMap['completedAt'] ?? todoMap['completed_at']),
          tags: _asDynamicList(todoMap['tags'])
              .map((tag) => tag.toString())
              .where((tag) => tag.isNotEmpty)
              .toList(),
        ),
      );
    } catch (_) {
      continue;
    }
  }
  return todos.isEmpty ? null : todos;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final value = candidate.toString().trim();
    if (value.isNotEmpty && value != 'null') {
      return value;
    }
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    if (value.isEmpty) return null;
    final asInt = int.tryParse(value);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(value);
  }
  return null;
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, mapValue) => MapEntry(key.toString(), mapValue),
        );
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}
