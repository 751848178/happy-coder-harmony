part of 'auth_models.dart';

class AccessKey {
  const AccessKey({
    required this.id,
    required this.key,
    required this.name,
    required this.createdAt,
    this.expiresAt,
    required this.active,
  });

  final String id;
  final String key;
  final String name;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool active;

  factory AccessKey.fromJson(Map<String, dynamic> json) {
    return AccessKey(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'active': active,
    };
  }
}

class SessionMessage {
  const SessionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory SessionMessage.fromJson(Map<String, dynamic> json) {
    return SessionMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class Artifact {
  const Artifact({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.type,
    required this.size,
    this.url,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  final String id;
  final String sessionId;
  final String name;
  final String type;
  final int size;
  final String? url;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? 'file',
      size: json['size'] as int? ?? 0,
      url: json['url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'name': name,
      'type': type,
      'size': size,
      if (url != null) 'url': url,
      'created_at': createdAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class KVPair {
  const KVPair({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  final String key;
  final String value;
  final DateTime updatedAt;

  factory KVPair.fromJson(Map<String, dynamic> json) {
    return KVPair(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
