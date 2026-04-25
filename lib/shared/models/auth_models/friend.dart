part of 'auth_models.dart';

class Friend {
  const Friend({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

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
