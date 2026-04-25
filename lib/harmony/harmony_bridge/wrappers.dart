part of 'harmony_bridge.dart';

Future<bool> _harmonyConnectLiveKit(String token) {
  return HarmonyBridge._liveKit.connectSession(token);
}

Future<void> _harmonyDisconnectLiveKit() {
  return HarmonyBridge._liveKit.disconnect();
}

Future<void> _harmonySendLiveKitAudio(Uint8List data) {
  return HarmonyBridge._liveKit.sendAudio(data);
}

Future<void> _harmonyToggleLiveKitMute() {
  return HarmonyBridge._liveKit.toggleMute();
}

Future<bool> _harmonyGetLiveKitMuted() {
  return HarmonyBridge._liveKit.getMuted();
}

Future<String?> _harmonyGenerateEncryptionKey() {
  return HarmonyBridge._crypto.generateKey();
}

Future<Map<String, String>?> _harmonyGenerateKeyPair() {
  return HarmonyBridge._crypto.generateKeyPair();
}

Future<String?> _harmonyEncrypt(String data, String key) {
  return HarmonyBridge._crypto.encrypt(data, key);
}

Future<String?> _harmonyDecrypt(String encrypted, String key) {
  return HarmonyBridge._crypto.decrypt(encrypted, key);
}

Future<String?> _harmonyEncryptForPublicKey(String data, String publicKey) {
  return HarmonyBridge._crypto.encryptForPublicKey(data, publicKey);
}

Future<String?> _harmonyDecryptFromPublicKey(
  String encrypted,
  String secretKey,
) {
  return HarmonyBridge._crypto.decryptFromPublicKey(encrypted, secretKey);
}

Future<String?> _harmonyHash(String data) {
  return HarmonyBridge._crypto.hash(data);
}

Future<Map<String, String>?> _harmonyAuthChallenge(String secretKey) {
  return HarmonyBridge._crypto.authChallenge(secretKey);
}

Future<String?> _harmonyGetPublicKey(String secretKey) {
  return HarmonyBridge._crypto.getPublicKey(secretKey);
}

Future<bool> _harmonyInitializePush(String appId) async {
  final initialized = await HarmonyBridge._push.initialize(appId);
  HarmonyBridge._isInitialized = HarmonyBridge._isInitialized || initialized;
  return initialized;
}

Future<bool> _harmonyRequestPushPermissions() {
  return HarmonyBridge._push.requestPermissions();
}

Future<String?> _harmonyGetInitialNotificationMessage() {
  return HarmonyBridge._push.getInitialMessage();
}

Stream<String> _harmonyOnPushNotification() {
  return HarmonyBridge._push.notifications();
}

Future<bool> _harmonyClearAllNotifications() {
  return HarmonyBridge._push.clearAll();
}

Future<bool> _harmonyClearNotification(String notificationId) {
  return HarmonyBridge._push.clear(notificationId);
}

Future<bool> _harmonyIsQRCodeAvailable() {
  return HarmonyBridge._qr.ping();
}

Future<String?> _harmonyGenerateQRCode(String data, {int size = 200}) {
  return HarmonyBridge._qr.generate(data, size: size);
}

Future<bool> _harmonyRequestQRCodePermission() {
  return HarmonyBridge._qr.requestCameraPermission();
}

Future<bool> _harmonyCheckQRCodePermission() {
  return HarmonyBridge._qr.checkCameraPermission();
}

Future<bool> _harmonyStartQRCodeScan({
  List<int> scanTypes = const <int>[],
  bool supportGallery = false,
}) {
  return HarmonyBridge._qr.startScan(
    scanTypes: scanTypes,
    supportGallery: supportGallery,
  );
}

Future<void> _harmonyStopQRCodeScan() {
  return HarmonyBridge._qr.stopScan();
}

Stream<Map<String, dynamic>> _harmonyQrScanEvents() {
  return HarmonyBridge._qr.scanEvents();
}

Stream<String?> _harmonyScanQRCode() {
  return HarmonyBridge._qr.scanResults();
}

Future<List<String>?> _harmonySelectFiles(List<String> mimeTypes) {
  return HarmonyBridge._file.selectFiles(mimeTypes);
}

Future<String?> _harmonySelectImage() {
  return HarmonyBridge._file.selectImage();
}

Future<Map<String, dynamic>?> _harmonyGetFileInfo(String path) {
  return HarmonyBridge._file.getInfo(path);
}

Future<Map<String, dynamic>?> _harmonyGetDeviceInfo() {
  return HarmonyBridge._device.getInfo();
}

Future<String?> _harmonyGetNetworkStatus() {
  return HarmonyBridge._device.getNetworkStatus();
}

Future<Map<String, dynamic>?> _harmonyGetBatteryInfo() {
  return HarmonyBridge._device.getBatteryInfo();
}

Future<bool> _harmonyRequestCameraPermission() {
  return HarmonyBridge._device.requestCameraPermission();
}

Future<bool> _harmonyRequestMicrophonePermission() {
  return HarmonyBridge._device.requestMicrophonePermission();
}

Future<bool> _harmonyRequestStoragePermission() {
  return HarmonyBridge._device.requestStoragePermission();
}

Future<void> _harmonyOpenAppSettings() {
  return HarmonyBridge._device.openAppSettings();
}

Future<bool> _harmonySetClipboardText(String text) {
  return HarmonyBridge._device.setClipboardText(text);
}

Future<String?> _harmonyGetClipboardText() {
  return HarmonyBridge._device.getClipboardText();
}
