part of 'friends_repository.dart';

Options _friendsAuthOptions(FriendsRepository repository, String? token) {
  if (token == null) {
    return Options();
  }
  return Options(
    headers: {
      ...repository._client.options.headers,
      'Authorization': 'Bearer $token',
    },
  );
}

Future<List<Friend>> _getFriends(
  FriendsRepository repository, {
  String? token,
}) async {
  try {
    Logger.info('Fetching friends list');
    final response = await repository._client.get(
      '/v1/friends',
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch friends: ${response.statusCode}');
    }
    final users = _extractRelationshipUsers(response.data);
    final friends = users
        .where((user) => user.status == FriendStatus.friend)
        .map((user) => Friend(
              id: user.id,
              userId: user.id,
              name: user.name,
              avatarUrl: user.avatarUrl,
              createdAt: DateTime.now(),
            ))
        .toList();
    Logger.info('Fetched ${friends.length} friends');
    return friends;
  } on DioException catch (error) {
    Logger.error('Get friends error: ${error.message}');
    rethrow;
  }
}

Future<List<UserSearchResult>> _getRelationshipUsers(
  FriendsRepository repository, {
  String? token,
}) async {
  try {
    final response = await repository._client.get(
      '/v1/friends',
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch relationships: ${response.statusCode}');
    }
    return _extractRelationshipUsers(response.data);
  } on DioException catch (error) {
    Logger.error('Get relationships error: ${error.message}');
    rethrow;
  }
}

Future<Map<String, dynamic>> _addFriend(
  FriendsRepository repository,
  String uid, {
  String? token,
}) async {
  try {
    Logger.info('Adding friend: $uid');
    final response = await repository._client.post(
      '/v1/friends/add',
      data: {'uid': uid},
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add friend: ${response.statusCode}');
    }
    Logger.info('Friend request sent/accepted');
    return response.data as Map<String, dynamic>;
  } on DioException catch (error) {
    Logger.error('Add friend error: ${error.message}');
    rethrow;
  }
}

Future<void> _removeFriend(
  FriendsRepository repository,
  String uid, {
  String? token,
}) async {
  try {
    Logger.info('Removing friend: $uid');
    final response = await repository._client.post(
      '/v1/friends/remove',
      data: {'uid': uid},
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove friend: ${response.statusCode}');
    }
    Logger.info('Friend removed successfully');
  } on DioException catch (error) {
    Logger.error('Remove friend error: ${error.message}');
    rethrow;
  }
}

Future<List<UserSearchResult>> _searchUsers(
  FriendsRepository repository,
  String query, {
  String? token,
}) async {
  try {
    Logger.info('Searching users: $query');
    final response = await repository._client.get(
      '/v1/user/search',
      queryParameters: {'query': query},
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to search users: ${response.statusCode}');
    }
    final users = _extractUsersFromResponse(response.data, key: 'users');
    Logger.info('Found ${users.length} users matching "$query"');
    return users;
  } on DioException catch (error) {
    Logger.error('Search users error: ${error.message}');
    rethrow;
  }
}

Future<UserSearchResult> _getFriendUserProfile(
  FriendsRepository repository,
  String uid, {
  String? token,
}) async {
  try {
    Logger.info('Fetching user profile: $uid');
    final response = await repository._client.get(
      '/v1/user/$uid',
      options: _friendsAuthOptions(repository, token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user profile: ${response.statusCode}');
    }
    final data = response.data;
    final payload = data is Map<String, dynamic>
        ? (data['user'] as Map<String, dynamic>? ?? data)
        : const <String, dynamic>{};
    final user = _parseRelationshipUser(payload);
    Logger.info('Fetched user profile for $uid');
    return user;
  } on DioException catch (error) {
    Logger.error('Get user profile error: ${error.message}');
    rethrow;
  }
}
