/// 认证相关数据模型

/// 加密类型
enum EncryptionType {
  legacy,
  sodium,
  rsa,
}

extension EncryptionTypeExtension on EncryptionType {
  String toValue() => name;
}

extension EncryptionTypeString on String {
  EncryptionType toEncryptionType() {
    return EncryptionType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => EncryptionType.legacy,
    );
  }
}

/// 凭证信息
class Credentials {
  final String token;
  final String machineId;
  final String encryptionKey;
  final EncryptionType encryptionType;
  final String? publicKey;
  final String? machineKey;
  final String? secret; // Happy Coder format stores secret key

  const Credentials({
    required this.token,
    required this.machineId,
    required this.encryptionKey,
    required this.encryptionType,
    this.publicKey,
    this.machineKey,
    this.secret,
  });

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
      token: json['token'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      encryptionKey: json['encryptionKey'] as String? ?? '',
      encryptionType: (json['encryptionType'] as String?)
          ?.toEncryptionType() ?? EncryptionType.legacy,
      publicKey: json['publicKey'] as String?,
      machineKey: json['machineKey'] as String?,
      secret: json['secret'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'machineId': machineId,
      'encryptionKey': encryptionKey,
      'encryptionType': encryptionType.toValue(),
      if (publicKey != null) 'publicKey': publicKey,
      if (machineKey != null) 'machineKey': machineKey,
      if (secret != null) 'secret': secret,
    };
  }
}

/// 用户信息
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? githubUsername;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.githubUsername,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      githubUsername: json['githubUsername'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  String toJson() {
    return ''; // Simple implementation for now
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (githubUsername != null) 'githubUsername': githubUsername,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  String toJsonString() {
    return toMap().toString();
  }
}

// ========== Happy API Models ==========

/// Access Key 模型
class AccessKey {
  final String id;
  final String key;
  final String name;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool active;

  const AccessKey({
    required this.id,
    required this.key,
    required this.name,
    required this.createdAt,
    this.expiresAt,
    required this.active,
  });

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

/// Session Message 模型
class SessionMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const SessionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

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

/// Artifact 模型
class Artifact {
  final String id;
  final String sessionId;
  final String name;
  final String type;
  final int size;
  final String? url;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

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

/// KV 键值对模型
class KVPair {
  final String key;
  final String value;
  final DateTime updatedAt;

  const KVPair({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

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

/// Friend 模型
class Friend {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const Friend({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 好友关系状态
enum FriendStatus {
  none,       // 无关系
  requested,  // 已发送请求
  pending,    // 对方发送的待处理请求
  friend,     // 已是好友
  rejected,   // 已拒绝
}

/// 收件箱项目类型
enum InboxItemType {
  friendRequest,  // 好友请求
  notification,  // 通知
  message,       // 消息
}

/// 收件箱项目
class InboxItem {
  final String id;
  final InboxItemType type;
  final String title;
  final String? description;
  final String? userId;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? metadata;

  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.createdAt,
    this.read = false,
    this.metadata,
  });

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    InboxItemType itemType;
    switch (type) {
      case 'friend_request':
        itemType = InboxItemType.friendRequest;
        break;
      case 'notification':
        itemType = InboxItemType.notification;
        break;
      case 'message':
        itemType = InboxItemType.message;
        break;
      default:
        itemType = InboxItemType.notification;
    }

    return InboxItem(
      id: json['id'] as String? ?? '',
      type: itemType,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      read: json['read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 好友请求工厂方法
  factory InboxItem.friendRequest({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required DateTime createdAt,
  }) {
    return InboxItem(
      id: 'fr_$userId',
      type: InboxItemType.friendRequest,
      title: '好友请求',
      description: '$userName 想要添加你为好友',
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      createdAt: createdAt,
      read: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _typeToString(type),
      'title': title,
      if (description != null) 'description': description,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      'created_at': createdAt.toIso8601String(),
      'read': read,
      if (metadata != null) 'metadata': metadata,
    };
  }

  String _typeToString(InboxItemType type) {
    switch (type) {
      case InboxItemType.friendRequest:
        return 'friend_request';
      case InboxItemType.notification:
        return 'notification';
      case InboxItemType.message:
        return 'message';
    }
  }
}

extension FriendStatusExtension on FriendStatus {
  String toValue() => name;
}

extension FriendStatusString on String {
  FriendStatus toFriendStatus() {
    return FriendStatus.values.firstWhere(
      (e) => e.name == this,
      orElse: () => FriendStatus.none,
    );
  }
}

/// 用户搜索结果（包含关系状态）
class UserSearchResult {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? githubUsername;
  final FriendStatus status;

  const UserSearchResult({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.githubUsername,
    required this.status,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      githubUsername: json['github_username'] as String? ??
          json['githubUsername'] as String?,
      status: (json['status'] as String?)?.toFriendStatus() ?? FriendStatus.none,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (githubUsername != null) 'github_username': githubUsername,
      'status': status.toValue(),
    };
  }
}

/// Connect Token 模型
class ConnectToken {
  final String token;
  final String? type;
  final DateTime expiresAt;

  const ConnectToken({
    required this.token,
    this.type,
    required this.expiresAt,
  });

  factory ConnectToken.fromJson(Map<String, dynamic> json) {
    return ConnectToken(
      token: json['token'] as String? ?? '',
      type: json['type'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now(),
    );
  }
}
