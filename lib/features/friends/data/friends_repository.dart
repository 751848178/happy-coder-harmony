import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/auth_models.dart'
    show Friend, UserSearchResult, FriendStatus;
import '../../../shared/utils/extensions.dart';

/// Friends Repository
///
/// Handles all friends-related API operations
class FriendsRepository {
  FriendsRepository._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.serverUrl,
    connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': AppConfig.userAgent,
    },
  ));

  /// Get repository instance
  static final FriendsRepository instance = FriendsRepository._();

  /// Get current user's friends list
  ///
  /// Returns list of confirmed friends
  Future<List<Friend>> getFriends({String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      Logger.info('Fetching friends list');
      final response = await _dio.get('/v1/friends', options: options);

      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map<String, dynamic>
            ? data['friends'] as List<dynamic>? ?? const <dynamic>[]
            : data is List
                ? data
                : const <dynamic>[];
        final friends = items
            .map((e) => _parseRelationshipUser(e as Map<String, dynamic>))
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
      } else {
        throw Exception('Failed to fetch friends: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Get friends error: ${e.message}');
      rethrow;
    }
  }

  /// Get all relationships for inbox grouping.
  Future<List<UserSearchResult>> getRelationshipUsers({String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      final response = await _dio.get('/v1/friends', options: options);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch relationships: ${response.statusCode}');
      }

      final data = response.data;
      final items = data is Map<String, dynamic>
          ? data['friends'] as List<dynamic>? ?? const <dynamic>[]
          : data is List
              ? data
              : const <dynamic>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(_parseRelationshipUser)
          .toList();
    } on DioException catch (e) {
      Logger.error('Get relationships error: ${e.message}');
      rethrow;
    }
  }

  /// Add friend (send request or accept pending request)
  ///
  /// [uid] The user ID to add as friend
  /// [token] Optional auth token (uses current if not provided)
  ///
  /// Returns updated user with new relationship status
  Future<Map<String, dynamic>> addFriend(String uid, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      Logger.info('Adding friend: $uid');
      final response = await _dio.post(
        '/v1/friends/add',
        data: {'uid': uid},
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        Logger.info('Friend request sent/accepted');
        return data;
      } else {
        throw Exception('Failed to add friend: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Add friend error: ${e.message}');
      rethrow;
    }
  }

  /// Remove friend
  ///
  /// [uid] The user ID to remove from friends
  /// [token] Optional auth token (uses current if not provided)
  Future<void> removeFriend(String uid, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      Logger.info('Removing friend: $uid');
      final response = await _dio.post(
        '/v1/friends/remove',
        data: {'uid': uid},
        options: options,
      );

      if (response.statusCode == 200) {
        Logger.info('Friend removed successfully');
      } else {
        throw Exception('Failed to remove friend: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Remove friend error: ${e.message}');
      rethrow;
    }
  }

  /// Search users by username
  ///
  /// [query] The username to search for
  /// [token] Optional auth token (uses current if not provided)
  ///
  /// Returns up to 10 matching users with relationship status
  Future<List<UserSearchResult>> searchUsers(String query,
      {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      Logger.info('Searching users: $query');
      final response = await _dio.get(
        '/v1/user/search',
        queryParameters: {'query': query},
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map<String, dynamic>
            ? data['users'] as List<dynamic>? ?? const <dynamic>[]
            : data is List
                ? data
                : const <dynamic>[];
        final users = items
            .whereType<Map<String, dynamic>>()
            .map(_parseRelationshipUser)
            .toList();
        Logger.info('Found ${users.length} users matching "$query"');
        return users;
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Search users error: ${e.message}');
      rethrow;
    }
  }

  /// Get user profile by ID
  ///
  /// [uid] The user ID to fetch profile for
  /// [token] Optional auth token (uses current if not provided)
  ///
  /// Returns user profile with relationship status
  Future<UserSearchResult> getUserProfile(String uid, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {
              ..._dio.options.headers,
              'Authorization': 'Bearer $token',
            })
          : Options();

      Logger.info('Fetching user profile: $uid');
      final response = await _dio.get(
        '/v1/user/$uid',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payload = data is Map<String, dynamic>
            ? (data['user'] as Map<String, dynamic>? ?? data)
            : const <String, dynamic>{};
        final user = _parseRelationshipUser(payload);
        Logger.info('Fetched user profile for $uid');
        return user;
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Get user profile error: ${e.message}');
      rethrow;
    }
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
}
