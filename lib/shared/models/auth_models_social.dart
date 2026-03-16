part of 'auth_models.dart';

enum FriendStatus {
  none,
  requested,
  pending,
  friend,
  rejected,
}

enum InboxItemType {
  friendRequest,
  notification,
  message,
}

class InboxItem {
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

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String?) {
      'friend_request' => InboxItemType.friendRequest,
      'message' => InboxItemType.message,
      _ => InboxItemType.notification,
    };
    return InboxItem(
      id: json['id'] as String? ?? '',
      type: type,
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
      (candidate) => candidate.name == this,
      orElse: () => FriendStatus.none,
    );
  }
}

class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.githubUsername,
    required this.status,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? githubUsername;
  final FriendStatus status;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      githubUsername: json['github_username'] as String? ??
          json['githubUsername'] as String?,
      status:
          (json['status'] as String?)?.toFriendStatus() ?? FriendStatus.none,
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

class ConnectToken {
  const ConnectToken({
    required this.token,
    this.type,
    required this.expiresAt,
  });

  final String token;
  final String? type;
  final DateTime expiresAt;

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
