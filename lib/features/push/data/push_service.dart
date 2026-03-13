import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../shared/utils/extensions.dart';
import '../../../harmony/harmony_bridge.dart';

/// 推送通知服务
///
/// 处理应用内推送通知
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// Flutter Local Notifications 插件
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 推送通知流
  final _notificationController = StreamController<PushNotification>.broadcast();

  /// 通知点击流
  final _notificationTapController = StreamController<NotificationTap>.broadcast();

  /// 推送通知流
  Stream<PushNotification> get notificationStream =>
      _notificationController.stream;

  /// 通知点击流
  Stream<NotificationTap> get notificationTapStream =>
      _notificationTapController.stream;

  /// 初始化
  Future<void> initialize({required String appId}) async {
    try {
      // HarmonyOS 平台初始化
      if (HarmonyBridge.isHarmonyOS) {
        final success = await HarmonyBridge.initializePush(appId);
        if (success) {
          await HarmonyBridge.requestPushPermissions();
          Logger.info('Push service initialized (HarmonyOS)');
        } else {
          Logger.warning('Push service initialization failed');
        }
        _listenToHarmonyPushEvents();
      }

      // 初始化 Flutter Local Notifications（通用平台）
      await _initializeLocalNotifications();

      Logger.info('Push service initialized');
    } catch (e) {
      Logger.error('Failed to initialize push service: $e');
    }
  }

  /// 初始化本地通知
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (details) => _onNotificationTap(details),
    );

    Logger.info('Local notifications initialized');
  }

  /// 监听 HarmonyOS 推送事件
  void _listenToHarmonyPushEvents() {
    HarmonyBridge.onPushNotification().listen((message) {
      final notification = _parsePushMessage(message);
      if (notification != null) {
        _notificationController.add(notification);
        _showLocalNotification(notification);
      }
    });
  }

  /// 解析推送消息
  PushNotification? _parsePushMessage(String message) {
    try {
      final json = message.startsWith('{') ? message : jsonEncode({'raw': message});

      final parsed = jsonDecode(json) as Map<String, dynamic>;

      final type = parsed['type'] as String?;
      final data = parsed['data'] as Map<String, dynamic>?;

      if (type == null) {
        // 尝试从原始消息解析
        return PushNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '新消息',
          body: message,
          timestamp: DateTime.now(),
          type: NotificationType.message,
        );
      }

      switch (type) {
        case 'message':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: data?['title'] as String? ?? '新消息',
            body: data?['body'] as String? ?? message,
            timestamp: DateTime.now(),
            type: NotificationType.message,
            sessionId: data?['sessionId'] as String?,
          );
        case 'session_update':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '会话更新',
            body: '你的会话"${data?['title'] ?? ''}"有新消息',
            timestamp: DateTime.now(),
            type: NotificationType.sessionUpdate,
            sessionId: data?['sessionId'] as String?,
          );
        case 'tool_approval':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '工具请求',
            body: 'Claude 请求使用"${data?['tool'] ?? ''}"工具',
            timestamp: DateTime.now(),
            type: NotificationType.toolApproval,
            toolName: data?['tool'] as String?,
          );
        case 'control_request':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '控制权请求',
            body: '来自 "${data?['deviceName'] ?? ''}" 的控制权请求',
            timestamp: DateTime.now(),
            type: NotificationType.controlRequest,
            deviceName: data?['deviceName'] as String?,
          );
        case 'control_granted':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '控制权已授予',
            body: '控制权已授予给 "${data?['deviceName'] ?? ''}"',
            timestamp: DateTime.now(),
            type: NotificationType.controlGranted,
          );
        case 'control_released':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '控制权已释放',
            body: '控制权已释放',
            timestamp: DateTime.now(),
            type: NotificationType.controlReleased,
          );
        case 'build_complete':
          return PushNotification(
            id: parsed['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: '构建完成',
            body: data?['message'] as String? ?? '项目构建完成',
            timestamp: DateTime.now(),
            type: NotificationType.buildComplete,
          );
        default:
          Logger.warning('Unknown push notification type: $type');
          return null;
      }
    } catch (e) {
      Logger.error('Failed to parse push message: $e');
      return PushNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '通知',
        body: message,
        timestamp: DateTime.now(),
        type: NotificationType.unknown,
      );
    }
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(PushNotification notification) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _getChannelKey(notification.type),
        _getChannelTitle(notification.type),
        channelDescription: _getChannelDescription(notification.type),
        importance: _getImportance(notification.type),
        priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: notification.type.shouldAlert,
        presentSound: true,
        badgeNumber: 1,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        int.tryParse(notification.id) ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
        notification.title,
        notification.body,
        details,
        payload: _buildPayload(notification),
      );

      Logger.info('Local notification shown: ${notification.type.name}');
    } catch (e) {
      Logger.error('Failed to show local notification: $e');
    }
  }

  /// 获取通知渠道 key
  String _getChannelKey(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'message_channel';
      case NotificationType.sessionUpdate:
        return 'session_channel';
      case NotificationType.toolApproval:
        return 'tool_channel';
      case NotificationType.controlRequest:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
        return 'control_channel';
      case NotificationType.buildComplete:
        return 'build_channel';
      default:
        return 'default_channel';
    }
  }

  /// 获取通知渠道标题
  String _getChannelTitle(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return '消息通知';
      case NotificationType.sessionUpdate:
        return '会话通知';
      case NotificationType.toolApproval:
        return '工具请求';
      case NotificationType.controlRequest:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
        return '控制权';
      case NotificationType.buildComplete:
        return '构建状态';
      default:
        return '默认通知';
    }
  }

  /// 获取通知渠道描述
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return '收到新消息时显示通知';
      case NotificationType.sessionUpdate:
        return '会话更新时显示通知';
      case NotificationType.toolApproval:
        return '有工具调用待批准时显示通知';
      case NotificationType.controlRequest:
        return '有设备请求控制权时显示通知';
      case NotificationType.controlGranted:
        return '控制权授予时显示通知';
      case NotificationType.controlReleased:
        return '控制权释放时显示通知';
      case NotificationType.buildComplete:
        return '构建完成时显示通知';
      default:
        return '通用通知';
    }
  }

  /// 获取重要性
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.message:
      case NotificationType.toolApproval:
      case NotificationType.controlRequest:
        return Importance.high;
      case NotificationType.sessionUpdate:
      case NotificationType.controlGranted:
      case NotificationType.controlReleased:
      case NotificationType.buildComplete:
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }

  /// 构建通知 payload
  String _buildPayload(PushNotification notification) {
    final buffer = StringBuffer();
    buffer.write('id=${notification.id}');
    buffer.write('&type=${notification.type.name}');
    if (notification.sessionId != null) {
      buffer.write('&sessionId=${notification.sessionId}');
    }
    return buffer.toString();
  }

  /// 处理通知点击
  void _onNotificationTap(NotificationResponse? response) {
    if (response == null) return;

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    Logger.info('Notification tapped: $payload');

    final parsed = _parsePayload(payload);

    _notificationTapController.add(NotificationTap(
      notificationId: parsed['id'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (parsed['type'] as String?),
        orElse: () => NotificationType.unknown,
      ),
      sessionId: parsed['sessionId'] as String?,
    ));
  }

  /// 解析 payload
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return Map<String, dynamic>.fromEntries(
        payload.split('&').map((pair) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            return MapEntry(parts[0], parts[1]);
          }
          return MapEntry(pair, '');
        }),
      );
    } catch (e) {
      Logger.error('Failed to parse payload: $e');
      return {};
    }
  }

  /// 创建通知渠道（Android）
  Future<void> createNotificationChannels() async {
    for (final type in NotificationType.values) {
      final channel = AndroidNotificationChannel(
        _getChannelKey(type),
        _getChannelTitle(type),
        description: _getChannelDescription(type),
        importance: _getImportance(type),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    Logger.info('Notification channels created');
  }

  /// 获取本地通知权限
  Future<bool> requestLocalPermissions() async {
    try {
      // Android
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final hasAndroidPermission = androidImpl != null;

      // iOS
      final iosResult = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
      final hasIOSPermission = iosResult == true;

      final hasPermission = hasAndroidPermission && hasIOSPermission;

      if (!hasPermission) {
        Logger.warning('Notification permissions denied');
      }

      return hasPermission;
    } catch (e) {
      Logger.error('Failed to request permissions: $e');
      return false;
    }
  }

  /// 清除所有通知
  Future<void> clearNotifications() async {
    try {
      await _localNotifications.cancelAll();
      Logger.info('All notifications cleared');
    } catch (e) {
      Logger.error('Failed to clear notifications: $e');
    }
  }

  /// 清除指定通知
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      Logger.info('Notification cancelled: $id');
    } catch (e) {
      Logger.error('Failed to cancel notification: $e');
    }
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    final notification = PushNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '测试通知',
      body: '这是一个测试推送通知',
      timestamp: DateTime.now(),
      type: NotificationType.message,
    );

    await _showLocalNotification(notification);
  }

  /// 释放资源
  void dispose() {
    _notificationController.close();
    _notificationTapController.close();
  }
}

/// 推送通知
class PushNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? sessionId;
  final String? toolName;
  final String? deviceName;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.sessionId,
    this.toolName,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      if (sessionId != null) 'sessionId': sessionId,
      if (toolName != null) 'toolName': toolName,
      if (deviceName != null) 'deviceName': deviceName,
    };
  }
}

/// 通知类型
enum NotificationType {
  /// 普通消息
  message,

  /// 会话更新
  sessionUpdate,

  /// 工具批准请求
  toolApproval,

  /// 控制权请求
  controlRequest,

  /// 控制权已授予
  controlGranted,

  /// 控制权已释放
  controlReleased,

  /// 构建完成
  buildComplete,

  /// 未知类型
  unknown;

  /// 是否应该显示弹窗提示
  bool get shouldAlert => this == message || this == toolApproval || this == controlRequest;
}

/// 通知点击事件
class NotificationTap {
  final String? notificationId;
  final NotificationType type;
  final String? sessionId;

  const NotificationTap({
    this.notificationId,
    required this.type,
    this.sessionId,
  });
}
