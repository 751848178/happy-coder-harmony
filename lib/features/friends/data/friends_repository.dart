import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/auth_models.dart'
    show Friend, FriendStatus, UserSearchResult;
import '../../../shared/utils/extensions.dart';

part 'friends_repository_parsing.dart';
part 'friends_repository_requests.dart';

class FriendsRepository {
  FriendsRepository._();

  static final FriendsRepository instance = FriendsRepository._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.serverUrl,
      connectTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': AppConfig.userAgent,
      },
    ),
  );

  Dio get _client {
    _dio.options.baseUrl = AppConfig.serverUrl;
    return _dio;
  }

  Future<List<Friend>> getFriends({String? token}) =>
      _getFriends(this, token: token);

  Future<List<UserSearchResult>> getRelationshipUsers({String? token}) =>
      _getRelationshipUsers(this, token: token);

  Future<Map<String, dynamic>> addFriend(String uid, {String? token}) =>
      _addFriend(this, uid, token: token);

  Future<void> removeFriend(String uid, {String? token}) =>
      _removeFriend(this, uid, token: token);

  Future<List<UserSearchResult>> searchUsers(String query, {String? token}) =>
      _searchUsers(this, query, token: token);

  Future<UserSearchResult> getUserProfile(String uid, {String? token}) =>
      _getFriendUserProfile(this, uid, token: token);
}
