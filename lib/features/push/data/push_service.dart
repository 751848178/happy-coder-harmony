import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../harmony/harmony_bridge.dart';
import '../../../shared/utils/extensions.dart';

part 'push_service_models.dart';
part 'push_service_notifications.dart';
part 'push_service_parsing.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _notificationController =
      StreamController<PushNotification>.broadcast();
  final _notificationTapController =
      StreamController<NotificationTap>.broadcast();
  StreamSubscription<String>? _harmonyPushSubscription;

  Stream<PushNotification> get notificationStream =>
      _notificationController.stream;
  Stream<NotificationTap> get notificationTapStream =>
      _notificationTapController.stream;

  Future<void> initialize({required String appId}) async {
    try {
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

      await _initializeLocalNotifications();
      Logger.info('Push service initialized');
    } catch (e) {
      Logger.error('Failed to initialize push service: $e');
    }
  }

  void dispose() {
    _harmonyPushSubscription?.cancel();
    _notificationController.close();
    _notificationTapController.close();
  }
}
