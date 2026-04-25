part of 'session_models.dart';

/// 在线状态
class PresenceStatus {
  final String status;
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
      return const PresenceStatus(status: 'offline');
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
