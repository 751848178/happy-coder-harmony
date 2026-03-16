part of 'push_service.dart';

extension _PushNotificationParsing on PushNotificationService {
  void _listenToHarmonyPushEvents() {
    _harmonyPushSubscription?.cancel();
    _harmonyPushSubscription = HarmonyBridge.onPushNotification().listen((
      message,
    ) {
      final notification = _parsePushMessage(message);
      if (notification == null) {
        return;
      }
      _notificationController.add(notification);
      _showLocalNotification(notification);
    });
  }

  PushNotification? _parsePushMessage(String message) {
    try {
      final rawJson =
          message.startsWith('{') ? message : jsonEncode({'raw': message});
      final parsed = jsonDecode(rawJson) as Map<String, dynamic>;
      final type = parsed['type'] as String?;
      final data = parsed['data'] as Map<String, dynamic>?;

      if (type == null) {
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
          return _buildNotification(
            parsed: parsed,
            title: data?['title'] as String? ?? '新消息',
            body: data?['body'] as String? ?? message,
            type: NotificationType.message,
            sessionId: data?['sessionId'] as String?,
          );
        case 'session_update':
          return _buildNotification(
            parsed: parsed,
            title: '会话更新',
            body: '你的会话"${data?['title'] ?? ''}"有新消息',
            type: NotificationType.sessionUpdate,
            sessionId: data?['sessionId'] as String?,
          );
        case 'tool_approval':
          return _buildNotification(
            parsed: parsed,
            title: '工具请求',
            body: 'Claude 请求使用"${data?['tool'] ?? ''}"工具',
            type: NotificationType.toolApproval,
            toolName: data?['tool'] as String?,
          );
        case 'control_request':
          return _buildNotification(
            parsed: parsed,
            title: '控制权请求',
            body: '来自 "${data?['deviceName'] ?? ''}" 的控制权请求',
            type: NotificationType.controlRequest,
            deviceName: data?['deviceName'] as String?,
          );
        case 'control_granted':
          return _buildNotification(
            parsed: parsed,
            title: '控制权已授予',
            body: '控制权已授予给 "${data?['deviceName'] ?? ''}"',
            type: NotificationType.controlGranted,
          );
        case 'control_released':
          return _buildNotification(
            parsed: parsed,
            title: '控制权已释放',
            body: '控制权已释放',
            type: NotificationType.controlReleased,
          );
        case 'build_complete':
          return _buildNotification(
            parsed: parsed,
            title: '构建完成',
            body: data?['message'] as String? ?? '项目构建完成',
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

  PushNotification _buildNotification({
    required Map<String, dynamic> parsed,
    required String title,
    required String body,
    required NotificationType type,
    String? sessionId,
    String? toolName,
    String? deviceName,
  }) {
    return PushNotification(
      id: parsed['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      sessionId: sessionId,
      toolName: toolName,
      deviceName: deviceName,
    );
  }
}
