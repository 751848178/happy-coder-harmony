import 'channel_invoker.dart';
import 'channel_names.dart';

class DeviceBridgeService extends HarmonyBridgeFeature {
  DeviceBridgeService._() : super(HarmonyChannelNames.device, 'device');

  static final DeviceBridgeService instance = DeviceBridgeService._();

  Future<Map<String, dynamic>?> getInfo() async {
    final result = await invoker.invoke<Map<dynamic, dynamic>>('getInfo');
    return toStringDynamicMap(result);
  }

  Future<String?> getNetworkStatus() async {
    return invoker.invoke<String>('getNetworkStatus');
  }

  Future<Map<String, dynamic>?> getBatteryInfo() async {
    final result =
        await invoker.invoke<Map<dynamic, dynamic>>('getBatteryInfo');
    return toStringDynamicMap(result);
  }

  Future<bool> requestCameraPermission() async {
    return (await invoker.invoke<bool>('requestCameraPermission')) ?? false;
  }

  Future<bool> requestMicrophonePermission() async {
    return (await invoker.invoke<bool>('requestMicrophonePermission')) ?? false;
  }

  Future<bool> requestStoragePermission() async {
    return (await invoker.invoke<bool>('requestStoragePermission')) ?? false;
  }

  Future<void> openAppSettings() async {
    await invoker.invoke<void>('openAppSettings');
  }

  Future<bool> setClipboardText(String text) async {
    return (await invoker.invoke<bool>(
          'setClipboard',
          arguments: {'text': text},
        )) ??
        false;
  }

  Future<String?> getClipboardText() async {
    return invoker.invoke<String>('getClipboard');
  }
}
