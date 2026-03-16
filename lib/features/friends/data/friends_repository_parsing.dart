part of 'friends_repository.dart';

List<UserSearchResult> _extractRelationshipUsers(dynamic data) {
  return _extractUsersFromResponse(data, key: 'friends');
}

List<UserSearchResult> _extractUsersFromResponse(
  dynamic data, {
  required String key,
}) {
  final items = data is Map<String, dynamic>
      ? data[key] as List<dynamic>? ?? const <dynamic>[]
      : data is List
          ? data
          : const <dynamic>[];
  return items
      .whereType<Map<String, dynamic>>()
      .map(_parseRelationshipUser)
      .toList();
}

UserSearchResult _parseRelationshipUser(Map<String, dynamic> json) {
  final avatar = json['avatar'];
  final avatarUrl = avatar is Map<String, dynamic>
      ? avatar['url'] as String?
      : avatar is Map
          ? avatar['url']?.toString()
          : json['avatar_url'] as String?;
  final firstName = json['firstName']?.toString().trim() ?? '';
  final lastName = json['lastName']?.toString().trim() ?? '';
  final username = json['username']?.toString().trim() ?? '';
  final fullName =
      [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim();

  return UserSearchResult(
    id: json['id']?.toString() ?? '',
    name: fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? username : '未命名用户'),
    avatarUrl: avatarUrl,
    bio: json['bio']?.toString(),
    githubUsername: username.isNotEmpty ? username : null,
    status: _parseFriendStatus(json['status']?.toString()),
  );
}

FriendStatus _parseFriendStatus(String? value) {
  for (final status in FriendStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return FriendStatus.none;
}
