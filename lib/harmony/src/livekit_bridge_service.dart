import 'dart:typed_data';

import 'channel_invoker.dart';
import 'channel_names.dart';

class LiveKitBridgeService extends HarmonyBridgeFeature {
  LiveKitBridgeService._() : super(HarmonyChannelNames.liveKit, 'livekit');

  static final LiveKitBridgeService instance = LiveKitBridgeService._();

  Future<bool> connectSession(String token) async {
    return (await invoker.invoke<bool>(
          'connectSession',
          arguments: {'token': token},
        )) ??
        false;
  }

  Future<void> disconnect() async {
    await invoker.invoke<void>('disconnect');
  }

  Future<void> sendAudio(Uint8List data) async {
    await invoker.invoke<void>(
      'sendAudio',
      arguments: {'data': data},
    );
  }

  Future<void> toggleMute() async {
    await invoker.invoke<void>('toggleMute');
  }

  Future<bool> getMuted() async {
    return (await invoker.invoke<bool>('getMuted')) ?? false;
  }
}
