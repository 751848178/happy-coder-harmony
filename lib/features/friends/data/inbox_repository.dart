import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/auth_models.dart' show InboxItem, InboxItemType;
import '../../../shared/utils/extensions.dart';

class InboxRepository {
  InboxRepository._();

  static final InboxRepository instance = InboxRepository._();

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

  Future<List<InboxItem>> getFeedItems({String? token}) async {
    try {
      final response = await _dio.get(
        '/v1/feed',
        options: _options(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch feed: ${response.statusCode}');
      }

      final payload = response.data;
      final items = payload is Map<String, dynamic>
          ? (payload['items'] as List<dynamic>? ??
              payload['feed'] as List<dynamic>? ??
              payload['updates'] as List<dynamic>? ??
              const <dynamic>[])
          : payload is List
              ? payload
              : const <dynamic>[];

      return items.whereType<Map<String, dynamic>>().map(_mapFeedItem).toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 404) {
        Logger.warning('Feed endpoint unavailable, fallback to empty inbox');
        return const <InboxItem>[];
      }
      Logger.error('Get feed items error: ${e.message}');
      rethrow;
    }
  }

  Future<List<InboxItem>> getInboxItems({String? token}) {
    return getFeedItems(token: token);
  }

  Future<void> markAsRead(String itemId, {String? token}) async {}

  Future<void> markAllAsRead({String? token}) async {}

  Future<void> deleteItem(String itemId, {String? token}) async {}

  Future<int> getUnreadCount({String? token}) async {
    return 0;
  }

  Options _options(String? token) {
    if (token == null || token.isEmpty) {
      return Options(headers: _dio.options.headers);
    }
    return Options(
      headers: {
        ..._dio.options.headers,
        'Authorization': 'Bearer $token',
      },
    );
  }

  InboxItem _mapFeedItem(Map<String, dynamic> json) {
    final body = json['body'];
    final bodyMap = body is Map<String, dynamic>
        ? body
        : body is Map
            ? body.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
    final kind = bodyMap['kind']?.toString() ?? 'text';
    final userId = bodyMap['uid']?.toString() ?? bodyMap['userId']?.toString();
    final createdAtMs = json['createdAt'];
    final createdAt = createdAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
        : DateTime.now();
    final description = bodyMap['text']?.toString() ??
        bodyMap['message']?.toString() ??
        bodyMap['description']?.toString() ??
        '有新的动态更新';

    switch (kind) {
      case 'friend_request':
        return InboxItem(
          id: json['id']?.toString() ??
              'feed_${createdAt.millisecondsSinceEpoch}',
          type: InboxItemType.friendRequest,
          title: '新的好友请求',
          description: '有人想要添加你为好友',
          userId: userId,
          createdAt: createdAt,
          read: false,
          metadata: {
            'kind': kind,
            'cursor': json['cursor'],
          },
        );
      case 'friend_accepted':
        return InboxItem(
          id: json['id']?.toString() ??
              'feed_${createdAt.millisecondsSinceEpoch}',
          type: InboxItemType.notification,
          title: '好友请求已接受',
          description: '对方已经接受了你的好友请求',
          userId: userId,
          createdAt: createdAt,
          read: false,
          metadata: {
            'kind': kind,
            'cursor': json['cursor'],
          },
        );
      default:
        return InboxItem(
          id: json['id']?.toString() ??
              'feed_${createdAt.millisecondsSinceEpoch}',
          type: InboxItemType.notification,
          title: '动态更新',
          description: description,
          userId: userId,
          createdAt: createdAt,
          read: false,
          metadata: {
            'kind': kind,
            'cursor': json['cursor'],
          },
        );
    }
  }
}
