part of 'push_service.dart';

extension PushNotificationDisplay on PushNotificationService {
  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    Logger.info('Local notifications initialized');
  }

  Future<void> _showLocalNotification(PushNotification notification) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          notification.type.channelKey,
          notification.type.channelTitle,
          channelDescription: notification.type.channelDescription,
          importance: notification.type.importance,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: notification.type.shouldAlert,
          presentSound: true,
          badgeNumber: 1,
        ),
      );

      await _localNotifications.show(
        int.tryParse(notification.id) ??
            DateTime.now().millisecondsSinceEpoch % 2147483647,
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

  String _buildPayload(PushNotification notification) {
    final buffer = StringBuffer()
      ..write('id=${notification.id}')
      ..write('&type=${notification.type.name}');
    if (notification.sessionId != null) {
      buffer.write('&sessionId=${notification.sessionId}');
    }
    return buffer.toString();
  }

  void _onNotificationTap(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    Logger.info('Notification tapped: $payload');
    final parsed = _parsePayload(payload);
    _notificationTapController.add(
      NotificationTap(
        notificationId: parsed['id'] as String?,
        type: NotificationType.values.firstWhere(
          (e) => e.name == (parsed['type'] as String?),
          orElse: () => NotificationType.unknown,
        ),
        sessionId: parsed['sessionId'] as String?,
      ),
    );
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return Map<String, dynamic>.fromEntries(
        payload.split('&').map((pair) {
          final parts = pair.split('=');
          return parts.length == 2
              ? MapEntry(parts[0], parts[1])
              : MapEntry(pair, '');
        }),
      );
    } catch (e) {
      Logger.error('Failed to parse payload: $e');
      return {};
    }
  }

  Future<void> createNotificationChannels() async {
    for (final type in NotificationType.values) {
      final channel = AndroidNotificationChannel(
        type.channelKey,
        type.channelTitle,
        description: type.channelDescription,
        importance: type.importance,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    Logger.info('Notification channels created');
  }

  Future<bool> requestLocalPermissions() async {
    try {
      final ios = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
      final hasPermission = ios ?? true;
      if (!hasPermission) {
        Logger.warning('Notification permissions denied');
      }
      return hasPermission;
    } catch (e) {
      Logger.error('Failed to request permissions: $e');
      return false;
    }
  }

  Future<void> clearNotifications() async {
    try {
      await _localNotifications.cancelAll();
      Logger.info('All notifications cleared');
    } catch (e) {
      Logger.error('Failed to clear notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      Logger.info('Notification cancelled: $id');
    } catch (e) {
      Logger.error('Failed to cancel notification: $e');
    }
  }

  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      PushNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '测试通知',
        body: '这是一个测试推送通知',
        timestamp: DateTime.now(),
        type: NotificationType.message,
      ),
    );
  }
}
