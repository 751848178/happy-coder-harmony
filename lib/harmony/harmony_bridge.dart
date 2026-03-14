import 'dart:typed_data';

import '../shared/utils/extensions.dart';
import 'src/crypto_bridge_service.dart';
import 'src/device_bridge_service.dart';
import 'src/file_bridge_service.dart';
import 'src/harmony_platform.dart';
import 'src/livekit_bridge_service.dart';
import 'src/push_bridge_service.dart';
import 'src/qr_bridge_service.dart';

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

  static Future<bool> connectLiveKit(String token) {
    return _liveKit.connectSession(token);
  }

  static Future<void> disconnectLiveKit() {
    return _liveKit.disconnect();
  }

  static Future<void> sendLiveKitAudio(Uint8List data) {
    return _liveKit.sendAudio(data);
  }

  static Future<void> toggleLiveKitMute() {
    return _liveKit.toggleMute();
  }

  static Future<bool> getLiveKitMuted() {
    return _liveKit.getMuted();
  }

  static Future<String?> generateEncryptionKey() {
    return _crypto.generateKey();
  }

  static Future<Map<String, String>?> generateKeyPair() {
    return _crypto.generateKeyPair();
  }

  static Future<String?> encrypt(String data, String key) {
    return _crypto.encrypt(data, key);
  }

  static Future<String?> decrypt(String encrypted, String key) {
    return _crypto.decrypt(encrypted, key);
  }

  static Future<String?> encryptForPublicKey(String data, String publicKey) {
    return _crypto.encryptForPublicKey(data, publicKey);
  }

  static Future<String?> decryptFromPublicKey(
    String encrypted,
    String secretKey,
  ) {
    return _crypto.decryptFromPublicKey(encrypted, secretKey);
  }

  static Future<String?> hash(String data) {
    return _crypto.hash(data);
  }

  static Future<Map<String, String>?> authChallenge(String secretKey) {
    return _crypto.authChallenge(secretKey);
  }

  static Future<String?> getPublicKey(String secretKey) {
    return _crypto.getPublicKey(secretKey);
  }

  static Future<bool> initializePush(String appId) async {
    final initialized = await _push.initialize(appId);
    _isInitialized = _isInitialized || initialized;
    return initialized;
  }

  static Future<bool> requestPushPermissions() {
    return _push.requestPermissions();
  }

  static Future<String?> getInitialNotificationMessage() {
    return _push.getInitialMessage();
  }

  static Stream<String> onPushNotification() {
    return _push.notifications();
  }

  static Future<bool> clearAllNotifications() {
    return _push.clearAll();
  }

  static Future<bool> clearNotification(String notificationId) {
    return _push.clear(notificationId);
  }

  static Future<bool> isQRCodeAvailable() {
    return _qr.ping();
  }

  static Future<String?> generateQRCode(String data, {int size = 200}) {
    return _qr.generate(data, size: size);
  }

  static Future<bool> requestQRCodePermission() {
    return _qr.requestCameraPermission();
  }

  static Future<bool> checkQRCodePermission() {
    return _qr.checkCameraPermission();
  }

  static Future<bool> startQRCodeScan({
    List<int> scanTypes = const <int>[],
    bool supportGallery = false,
  }) {
    return _qr.startScan(
      scanTypes: scanTypes,
      supportGallery: supportGallery,
    );
  }

  static Future<void> stopQRCodeScan() {
    return _qr.stopScan();
  }

  static Stream<Map<String, dynamic>> qrScanEvents() {
    return _qr.scanEvents();
  }

  static Stream<String?> scanQRCode() {
    return _qr.scanResults();
  }

  static Future<List<String>?> selectFiles(List<String> mimeTypes) {
    return _file.selectFiles(mimeTypes);
  }

  static Future<String?> selectImage() {
    return _file.selectImage();
  }

  static Future<Map<String, dynamic>?> getFileInfo(String path) {
    return _file.getInfo(path);
  }

  static Future<Map<String, dynamic>?> getDeviceInfo() {
    return _device.getInfo();
  }

  static Future<String?> getNetworkStatus() {
    return _device.getNetworkStatus();
  }

  static Future<Map<String, dynamic>?> getBatteryInfo() {
    return _device.getBatteryInfo();
  }

  static Future<bool> requestCameraPermission() {
    return _device.requestCameraPermission();
  }

  static Future<bool> requestMicrophonePermission() {
    return _device.requestMicrophonePermission();
  }

  static Future<bool> requestStoragePermission() {
    return _device.requestStoragePermission();
  }

  static Future<void> openAppSettings() {
    return _device.openAppSettings();
  }

  static Future<bool> setClipboardText(String text) {
    return _device.setClipboardText(text);
  }

  static Future<String?> getClipboardText() {
    return _device.getClipboardText();
  }
}
