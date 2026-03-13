import 'dart:convert';

import 'reducer.dart';

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
    DateTime? activeAt,
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
    DateTime? thinkingAt,
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
      activeAt: activeAt ?? this.activeAt,
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
      thinkingAt: thinkingAt ?? this.thinkingAt,
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
    final metadata = _asStringMap(json['metadata']);
    final agentState = _asStringMap(json['agentState']);
    final fallbackId = json['id']?.toString() ?? '';
    final metadataPath = metadata?['path']?.toString();
    final pathSegments = metadataPath
        ?.split('/')
        .where((item) => item.isNotEmpty)
        .toList();
    final title = (json['title'] as String?) ??
        (json['name'] as String?) ??
        metadata?['name']?.toString() ??
        metadata?['title']?.toString() ??
        (pathSegments != null && pathSegments.isNotEmpty ? pathSegments.last : null) ??
        (json['tag'] as String?) ??
        (fallbackId.isNotEmpty
            ? '会话 ${fallbackId.length > 8 ? fallbackId.substring(0, 8) : fallbackId}'
            : '未命名会话');
    return Session(
      id: fallbackId,
      seq: json['seq'] as int?,
      title: title,
      messages: json['messages'] as List<dynamic>? ?? [],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      active: json['active'] as bool? ?? true,
      activeAt: _parseDateTime(json['activeAt']),
      tag: json['tag'] as String?,
      path: json['path'] as String?,
      metadata: metadata,
      metadataVersion: json['metadataVersion'] as int?,
      permissionMode: json['permissionMode'] as String?,
      modelMode: json['modelMode'] as String?,
      draft: json['draft'] as String?,
      agentState: agentState,
      agentStateVersion: json['agentStateVersion'] as int?,
      todos: (json['todos'] as List<dynamic>?)
          ?.map((item) => Todo.fromJson(item as Map<String, dynamic>))
          .toList(),
      presence: json['presence'] != null
          ? PresenceStatus.fromDynamic(json['presence'])
          : null,
      thinking: json['thinking'] as bool?,
      thinkingAt: _parseDateTime(json['thinkingAt']),
      latestUsage: json['latestUsage'] != null
          ? LatestUsage.fromJson(json['latestUsage'] as Map<String, dynamic>)
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
    final status = json['status'] as String;
    final lastActiveAt = _parseDateTime(json['lastActiveAt']);
    final usersList = json['users'] as List<dynamic>?;
    final users = usersList != null
        ? usersList.map((u) => SessionPresence.fromJson(u as Map<String, dynamic>)).toList()
        : null;

    return PresenceStatus(
      status: status,
      lastActiveAt: lastActiveAt,
      users: users,
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
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      isOnline: json['isOnline'] as bool,
      lastSeenAt: _parseDateTime(json['lastSeenAt']),
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
      messageCount: json['messageCount'] as int? ??
          json['outputTokens'] as int? ??
          0,
      tokenCount: json['tokenCount'] as int? ??
          json['contextSize'] as int? ??
          json['inputTokens'] as int? ??
          0,
      timestamp: _parseDateTime(json['timestamp']) ?? DateTime.now(),
      filesAccessed: json['filesAccessed'] as int? ?? json['cacheRead'] as int?,
      toolsUsed: json['toolsUsed'] as int? ?? json['cacheCreation'] as int?,
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
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return Machine(
      id: json['id'] as String,
      seq: json['seq'] as int?,
      name: json['name'] as String? ??
          metadata?['displayName']?.toString() ??
          metadata?['host']?.toString() ??
          json['id'] as String,
      platform: json['platform'] as String? ?? metadata?['platform']?.toString(),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
      active: json['active'] as bool? ?? true,
      activeAt: _parseDateTime(json['activeAt']),
      metadata: metadata,
      metadataVersion: json['metadataVersion'] as int?,
    );
  }
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
