import 'package:flutter/services.dart';

import '../../shared/utils/extensions.dart';
import 'channel_invoker.dart';
import 'channel_names.dart';
import 'harmony_platform.dart';

class QrBridgeService extends HarmonyBridgeFeature {
  QrBridgeService._() : super(HarmonyChannelNames.qr, 'qrcode');

  static final QrBridgeService instance = QrBridgeService._();
  static const EventChannel _events =
      EventChannel(HarmonyChannelNames.qrEvents);

  Future<String?> generate(String data, {int size = 200}) async {
    return invoker.invoke<String>(
      'generate',
      arguments: {
        'data': data,
        'size': size,
      },
    );
  }

  Future<bool> requestCameraPermission() async {
    return (await invoker.invoke<bool>('requestCameraPermission')) ?? false;
  }

  Future<bool> checkCameraPermission() async {
    return (await invoker.invoke<bool>('checkCameraPermission')) ?? false;
  }

  Future<bool> startScan({
    List<int> scanTypes = const <int>[],
    bool supportGallery = false,
  }) async {
    return (await invoker.invoke<bool>(
          'startScan',
          arguments: {
            'scanTypes': scanTypes,
            'supportGallery': supportGallery,
          },
        )) ??
        false;
  }

  Future<void> stopScan() async {
    await invoker.invoke<void>('stopScan');
  }

  Stream<Map<String, dynamic>> scanEvents() {
    if (!HarmonyPlatform.isHarmonyOS) {
      return const Stream.empty();
    }

    return _events.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return event.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return <String, dynamic>{};
    }).handleError((Object error, StackTrace stackTrace) {
      Logger.error('[qrcode] event stream failed: $error');
    });
  }

  Stream<String?> scanResults() {
    return scanEvents()
        .where((event) => event['type'] == 'scan_success')
        .map((event) {
      final data = event['data'];
      if (data is Map) {
        final content = data['content'];
        if (content is String) {
          return content;
        }
      }

      final content = event['content'];
      return content is String ? content : null;
    });
  }
}
