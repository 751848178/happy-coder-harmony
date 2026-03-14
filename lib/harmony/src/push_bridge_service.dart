import 'package:flutter/services.dart';

import '../../shared/utils/extensions.dart';
import 'channel_invoker.dart';
import 'channel_names.dart';
import 'harmony_platform.dart';

class PushBridgeService extends HarmonyBridgeFeature {
  PushBridgeService._() : super(HarmonyChannelNames.push, 'push');

  static final PushBridgeService instance = PushBridgeService._();
  static const EventChannel _events =
      EventChannel(HarmonyChannelNames.pushEvents);

  Future<bool> initialize(String appId) async {
    return (await invoker.invoke<bool>(
          'initialize',
          arguments: {'appId': appId},
        )) ??
        false;
  }

  Future<bool> requestPermissions() async {
    return (await invoker.invoke<bool>('requestPermissions')) ?? false;
  }

  Future<String?> getInitialMessage() async {
    return invoker.invoke<String>('getInitialMessage');
  }

  Stream<String> notifications() {
    if (!HarmonyPlatform.isHarmonyOS) {
      return const Stream.empty();
    }

    return _events
        .receiveBroadcastStream()
        .map((event) => event.toString())
        .handleError(
      (Object error, StackTrace stackTrace) {
        Logger.error('[push] event stream failed: $error');
      },
    );
  }

  Future<bool> clearAll() async {
    return (await invoker.invoke<bool>('clearAll')) ?? false;
  }

  Future<bool> clear(String notificationId) async {
    return (await invoker.invoke<bool>(
          'clear',
          arguments: {'notificationId': notificationId},
        )) ??
        false;
  }
}
