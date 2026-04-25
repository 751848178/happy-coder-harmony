import 'dart:typed_data';

import '../../shared/utils/extensions.dart';
import '../src/crypto_bridge_service.dart';
import '../src/device_bridge_service.dart';
import '../src/file_bridge_service.dart';
import '../src/harmony_platform.dart';
import '../src/livekit_bridge_service.dart';
import '../src/push_bridge_service.dart';
import '../src/qr_bridge_service.dart';

part 'wrappers.dart';

/// Flutter HarmonyOS Bridge facade.
///
/// 对外保持兼容 API，对内按能力拆分为独立 bridge service，
/// 避免单个文件同时承担平台识别、通道管理、错误处理和业务适配。
class HarmonyBridge {
  HarmonyBridge._();

  static final HarmonyBridge instance = HarmonyBridge._();

  static final LiveKitBridgeService _liveKit = LiveKitBridgeService.instance;
  static final CryptoBridgeService _crypto = CryptoBridgeService.instance;
  static final PushBridgeService _push = PushBridgeService.instance;
  static final QrBridgeService _qr = QrBridgeService.instance;
  static final FileBridgeService _file = FileBridgeService.instance;
  static final DeviceBridgeService _device = DeviceBridgeService.instance;

  static bool _isInitialized = false;

  static bool get isHarmonyOS => HarmonyPlatform.isHarmonyOS;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (!isHarmonyOS) {
      Logger.info('Not running on HarmonyOS, skipping bridge initialization');
      return;
    }

    final availability = <String, bool>{
      'livekit': await _liveKit.ping(),
      'libsodium': await _crypto.ping(),
      'push': await _push.ping(),
      'qrcode': await _qr.ping(),
      'file': await _file.ping(),
      'device': await _device.ping(),
    };

    Logger.info(
      'Harmony bridge availability: ${availability.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
    );
    _isInitialized = true;
  }

  static final Future<bool> Function(String) connectLiveKit =
      _harmonyConnectLiveKit;
  static final Future<void> Function() disconnectLiveKit =
      _harmonyDisconnectLiveKit;
  static final Future<void> Function(Uint8List) sendLiveKitAudio =
      _harmonySendLiveKitAudio;
  static final Future<void> Function() toggleLiveKitMute =
      _harmonyToggleLiveKitMute;
  static final Future<bool> Function() getLiveKitMuted =
      _harmonyGetLiveKitMuted;

  static final Future<String?> Function() generateEncryptionKey =
      _harmonyGenerateEncryptionKey;
  static final Future<Map<String, String>?> Function() generateKeyPair =
      _harmonyGenerateKeyPair;
  static final Future<String?> Function(String, String) encrypt =
      _harmonyEncrypt;
  static final Future<String?> Function(String, String) decrypt =
      _harmonyDecrypt;
  static final Future<String?> Function(String, String) encryptForPublicKey =
      _harmonyEncryptForPublicKey;
  static final Future<String?> Function(String, String) decryptFromPublicKey =
      _harmonyDecryptFromPublicKey;
  static final Future<String?> Function(String) hash = _harmonyHash;
  static final Future<Map<String, String>?> Function(String) authChallenge =
      _harmonyAuthChallenge;
  static final Future<String?> Function(String) getPublicKey =
      _harmonyGetPublicKey;

  static final Future<bool> Function(String) initializePush =
      _harmonyInitializePush;
  static final Future<bool> Function() requestPushPermissions =
      _harmonyRequestPushPermissions;
  static final Future<String?> Function() getInitialNotificationMessage =
      _harmonyGetInitialNotificationMessage;
  static final Stream<String> Function() onPushNotification =
      _harmonyOnPushNotification;
  static final Future<bool> Function() clearAllNotifications =
      _harmonyClearAllNotifications;
  static final Future<bool> Function(String) clearNotification =
      _harmonyClearNotification;

  static final Future<bool> Function() isQRCodeAvailable =
      _harmonyIsQRCodeAvailable;
  static final Future<String?> Function(String, {int size}) generateQRCode =
      _harmonyGenerateQRCode;
  static final Future<bool> Function() requestQRCodePermission =
      _harmonyRequestQRCodePermission;
  static final Future<bool> Function() checkQRCodePermission =
      _harmonyCheckQRCodePermission;
  static final Future<bool> Function({
    List<int> scanTypes,
    bool supportGallery,
  }) startQRCodeScan = _harmonyStartQRCodeScan;
  static final Future<void> Function() stopQRCodeScan = _harmonyStopQRCodeScan;
  static final Stream<Map<String, dynamic>> Function() qrScanEvents =
      _harmonyQrScanEvents;
  static final Stream<String?> Function() scanQRCode = _harmonyScanQRCode;

  static final Future<List<String>?> Function(List<String>) selectFiles =
      _harmonySelectFiles;
  static final Future<String?> Function() selectImage = _harmonySelectImage;
  static final Future<Map<String, dynamic>?> Function(String) getFileInfo =
      _harmonyGetFileInfo;

  static final Future<Map<String, dynamic>?> Function() getDeviceInfo =
      _harmonyGetDeviceInfo;
  static final Future<String?> Function() getNetworkStatus =
      _harmonyGetNetworkStatus;
  static final Future<Map<String, dynamic>?> Function() getBatteryInfo =
      _harmonyGetBatteryInfo;
  static final Future<bool> Function() requestCameraPermission =
      _harmonyRequestCameraPermission;
  static final Future<bool> Function() requestMicrophonePermission =
      _harmonyRequestMicrophonePermission;
  static final Future<bool> Function() requestStoragePermission =
      _harmonyRequestStoragePermission;
  static final Future<void> Function() openAppSettings =
      _harmonyOpenAppSettings;
  static final Future<bool> Function(String) setClipboardText =
      _harmonySetClipboardText;
  static final Future<String?> Function() getClipboardText =
      _harmonyGetClipboardText;
}
