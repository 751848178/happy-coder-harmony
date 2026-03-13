import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../shared/utils/extensions.dart';

/// Flutter HarmonyOS Bridge
///
/// 提供鸿蒙原生功能的方法通道
/// 用于 LiveKit、libsodium、推送通知等
class HarmonyBridge {
  HarmonyBridge._();

  /// 单例实例
  static final HarmonyBridge instance = HarmonyBridge._();

  // ========== MethodChannel 实例 ==========

  /// LiveKit MethodChannel
  static const MethodChannel _channelLiveKit = MethodChannel('happy.livekit');

  /// Libsodium MethodChannel
  static const MethodChannel _channelLibsodium =
      MethodChannel('happy.libsodium');

  /// Push Notification MethodChannel
  static const MethodChannel _channelPush = MethodChannel('happy.push');

  /// QR Code MethodChannel
  static const MethodChannel _channelQR = MethodChannel('happy.qrcode');

  /// File Operations MethodChannel
  static const MethodChannel _channelFile = MethodChannel('happy.file');

  /// Device Info MethodChannel
  static const MethodChannel _channelDevice = MethodChannel('happy.device');

  // ========== 常量定义 ==========

  /// 是否已初始化
  static bool _isInitialized = false;

  // ========== LiveKit 实时语音 ==========

  /// 连接到 LiveKit 会话
  ///
  /// [token] 会话令牌
  /// 返回连接结果
  static Future<bool> connectLiveKit(String token) async {
    try {
      final result =
          await _channelLiveKit.invokeMethod<bool>('connectSession', {
        'token': token,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('LiveKit connect failed: ${e.message}');
      return false;
    }
  }

  /// 断开 LiveKit 会话
  static Future<void> disconnectLiveKit() async {
    try {
      await _channelLiveKit.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      Logger.error('LiveKit disconnect failed: ${e.message}');
    }
  }

  /// 发送音频数据
  ///
  /// [data] 音频数据
  static Future<void> sendLiveKitAudio(Uint8List data) async {
    try {
      await _channelLiveKit.invokeMethod<void>('sendAudio', {
        'data': data,
      });
    } on PlatformException catch (e) {
      Logger.error('LiveKit send audio failed: ${e.message}');
    }
  }

  /// 切换静音状态
  static Future<void> toggleLiveKitMute() async {
    try {
      await _channelLiveKit.invokeMethod<void>('toggleMute');
    } on PlatformException catch (e) {
      Logger.error('LiveKit toggle mute failed: ${e.message}');
    }
  }

  /// 获取静音状态
  static Future<bool> getLiveKitMuted() async {
    try {
      final result = await _channelLiveKit.invokeMethod<bool>('getMuted');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('LiveKit get muted failed: ${e.message}');
      return false;
    }
  }

  // ========== Libsodium 加密 ==========

  /// 生成加密密钥 (256-bit)
  ///
  /// 返回 Base64 编码的密钥
  static Future<String?> generateEncryptionKey() async {
    try {
      final result =
          await _channelLibsodium.invokeMethod<String>('generateKey');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium generateKey failed: ${e.message}');
      return null;
    }
  }

  /// 生成密钥对 (公钥 + 私钥)
  ///
  /// 返回 [publicKey, secretKey] 格式
  static Future<Map<String, String>?> generateKeyPair() async {
    try {
      final result = await _channelLibsodium
          .invokeMethod<Map<String, dynamic>>('generateKeyPair')
          .timeout(
            const Duration(seconds: 10), // 10秒超时
          );
      if (result == null) {
        Logger.error('Libsodium generateKeyPair timed out or returned null');
        return null;
      }
      return {
        'publicKey': result['publicKey'] as String,
        'secretKey': result['secretKey'] as String,
      };
    } on PlatformException catch (e) {
      Logger.error('Libsodium generateKeyPair failed: ${e.message}');
      return null;
    }
  }

  /// 使用密钥加密数据
  ///
  /// [data] 要加密的字符串
  /// [key] Base64 编码的密钥
  /// 返回加密后的数据
  static Future<String?> encrypt(String data, String key) async {
    try {
      final result = await _channelLibsodium.invokeMethod<String>('encrypt', {
        'data': data,
        'key': key,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium encrypt failed: ${e.message}');
      return null;
    }
  }

  /// 使用密钥解密数据
  ///
  /// [encrypted] 加密的数据
  /// [key] Base64 编码的密钥
  /// 返回解密后的数据
  static Future<String?> decrypt(String encrypted, String key) async {
    try {
      final result = await _channelLibsodium.invokeMethod<String>('decrypt', {
        'encrypted': encrypted,
        'key': key,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium decrypt failed: ${e.message}');
      return null;
    }
  }

  /// 使用公钥加密 (box_seal)
  ///
  /// [data] 要加密的字符串
  /// [publicKey] Base64 编码的公钥
  /// 返回加密后的数据
  static Future<String?> encryptForPublicKey(
      String data, String publicKey) async {
    try {
      final result =
          await _channelLibsodium.invokeMethod<String>('encryptForPublicKey', {
        'data': data,
        'publicKey': publicKey,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium encryptForPublicKey failed: ${e.message}');
      return null;
    }
  }

  /// 使用私钥解密 (box_open)
  ///
  /// [encrypted] 加密的数据
  /// [secretKey] Base64 编码的私钥
  /// 返回解密后的数据
  static Future<String?> decryptFromPublicKey(
      String encrypted, String secretKey) async {
    try {
      final result =
          await _channelLibsodium.invokeMethod<String>('decryptFromPublicKey', {
        'encrypted': encrypted,
        'secretKey': secretKey,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium decryptFromPublicKey failed: ${e.message}');
      return null;
    }
  }

  /// 计算哈希值
  ///
  /// [data] 要计算哈希的数据
  /// 返回 Base64 编码的哈希值
  static Future<String?> hash(String data) async {
    try {
      final result = await _channelLibsodium.invokeMethod<String>('hash', {
        'data': data,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium hash failed: ${e.message}');
      return null;
    }
  }

  // ========== 推送通知 ==========

  /// 初始化推送服务
  ///
  /// [appId] 应用 ID
  /// 返回是否成功
  static Future<bool> initializePush(String appId) async {
    try {
      final result = await _channelPush.invokeMethod<bool>('initialize', {
        'appId': appId,
      });
      _isInitialized = result ?? false;
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Push initialize failed: ${e.message}');
      return false;
    }
  }

  /// 请求推送权限
  ///
  /// 返回是否获得权限
  static Future<bool> requestPushPermissions() async {
    try {
      final result =
          await _channelPush.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Push request permissions failed: ${e.message}');
      return false;
    }
  }

  /// 获取应用启动时的初始通知消息
  ///
  /// 返回通知消息内容或 null
  static Future<String?> getInitialNotificationMessage() async {
    try {
      final result =
          await _channelPush.invokeMethod<String>('getInitialMessage');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Push get initial message failed: ${e.message}');
      return null;
    }
  }

  /// 订阅推送通知事件流
  ///
  /// 返回通知消息流
  static Stream<String> onPushNotification() {
    const eventChannel = EventChannel('happy.push/events');
    return eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => event as String);
  }

  /// 清除所有通知
  ///
  /// 返回是否成功
  static Future<bool> clearAllNotifications() async {
    try {
      final result = await _channelPush.invokeMethod<bool>('clearAll');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Push clear all notifications failed: ${e.message}');
      return false;
    }
  }

  /// 清除指定通知
  ///
  /// [notificationId] 通知 ID
  /// 返回是否成功
  static Future<bool> clearNotification(String notificationId) async {
    try {
      final result = await _channelPush.invokeMethod<bool>('clear', {
        'notificationId': notificationId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Push clear notification failed: ${e.message}');
      return false;
    }
  }

  // ========== 工具方法 ==========

  /// 检查平台是否为 HarmonyOS
  static bool get isHarmonyOS {
    if (kIsWeb) {
      return false;
    }

    final os = Platform.operatingSystem.toLowerCase();
    if (os == 'ohos' || os == 'harmonyos' || os == 'openharmony') {
      return true;
    }

    // Fallback for builds that expose HarmonyOS via environment markers
    final env = Platform.environment;
    return env.containsKey('OHOS') ||
        env.containsKey('HARMONYOS') ||
        env.containsKey('OPENHARMONY');
  }

  /// 初始化所有通道
  ///
  /// 应该在应用启动时调用
  static Future<void> initialize() async {
    if (!isHarmonyOS) {
      Logger.info('Not running on HarmonyOS, skipping bridge initialization');
      return;
    }

    try {
      // 检查通道可用性
      final liveKitAvailable = await _checkChannelAvailability(_channelLiveKit);
      final libsodiumAvailable =
          await _checkChannelAvailability(_channelLibsodium);
      final pushAvailable = await _checkChannelAvailability(_channelPush);
      final qrAvailable = await _checkChannelAvailability(_channelQR);
      final fileAvailable = await _checkChannelAvailability(_channelFile);
      final deviceAvailable = await _checkChannelAvailability(_channelDevice);

      Logger.info(
          'Channel availability: LiveKit=$liveKitAvailable, Libsodium=$libsodiumAvailable, Push=$pushAvailable, QR=$qrAvailable, File=$fileAvailable, Device=$deviceAvailable');
      _isInitialized = true;
    } catch (e) {
      Logger.error('Bridge initialization failed: $e');
    }
  }

  /// 检查 MethodChannel 是否可用
  static Future<bool> _checkChannelAvailability(MethodChannel channel) async {
    try {
      await channel.invokeMethod('ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isQRCodeAvailable() async {
    if (!isHarmonyOS) {
      return false;
    }
    return _checkChannelAvailability(_channelQR);
  }

  /// 获取桥接状态
  static bool get isInitialized => _isInitialized;

  // ========== QR 码扫描 ==========

  /// 生成 QR 码
  ///
  /// [data] QR 码内容
  /// [size] QR 码尺寸 (像素)
  /// 返回 Base64 编码的 QR 码图片
  static Future<String?> generateQRCode(String data, {int size = 200}) async {
    try {
      final result = await _channelQR.invokeMethod<String>('generate', {
        'data': data,
        'size': size,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('QR generate failed: ${e.message}');
      return null;
    }
  }

  static Future<bool> requestQRCodePermission() async {
    try {
      final granted =
          await _channelQR.invokeMethod<bool>('requestCameraPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      Logger.error('QR permission request failed: ${e.message}');
      return false;
    }
  }

  static Future<bool> checkQRCodePermission() async {
    try {
      final granted =
          await _channelQR.invokeMethod<bool>('checkCameraPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      Logger.error('QR permission check failed: ${e.message}');
      return false;
    }
  }

  static Future<bool> startQRCodeScan({
    List<int> scanTypes = const <int>[],
    bool supportGallery = false,
  }) async {
    try {
      final result = await _channelQR.invokeMethod<bool>('startScan', {
        'scanTypes': scanTypes,
        'supportGallery': supportGallery,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('QR start scan failed: ${e.message}');
      return false;
    }
  }

  static Future<void> stopQRCodeScan() async {
    try {
      await _channelQR.invokeMethod<void>('stopScan');
    } on PlatformException catch (e) {
      Logger.error('QR stop scan failed: ${e.message}');
    }
  }

  static Stream<Map<String, dynamic>> qrScanEvents() {
    try {
      const eventChannel = EventChannel('happy.qrcode/events');
      return eventChannel.receiveBroadcastStream().map((dynamic event) {
        if (event is Map) {
          return event.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
        return <String, dynamic>{};
      });
    } catch (e) {
      Logger.error('QR event stream failed: $e');
      return const Stream<Map<String, dynamic>>.empty();
    }
  }

  /// 开始扫描 QR 码
  ///
  /// 返回扫描到的 QR 码内容
  static Stream<String?> scanQRCode() {
    try {
      return qrScanEvents()
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
    } catch (e) {
      Logger.error('QR scan failed: $e');
      return const Stream.empty();
    }
  }

  // ========== 文件操作 ==========

  /// 选择文件
  ///
  /// [mimeTypes] 允许的 MIME 类型列表
  /// 返回文件路径列表
  static Future<List<String>?> selectFiles(List<String> mimeTypes) async {
    try {
      final result =
          await _channelFile.invokeMethod<List<dynamic>>('selectFiles', {
        'mimeTypes': mimeTypes,
      });
      if (result == null) return null;
      return result.map((e) => e as String).toList();
    } on PlatformException catch (e) {
      Logger.error('File select failed: ${e.message}');
      return null;
    }
  }

  /// 选择图片
  ///
  /// 返回图片文件路径
  static Future<String?> selectImage() async {
    try {
      final result = await _channelFile.invokeMethod<String>('selectImage');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Image select failed: ${e.message}');
      return null;
    }
  }

  /// 获取文件信息
  ///
  /// [path] 文件路径
  /// 返回文件信息 (size, mimeType, name)
  static Future<Map<String, dynamic>?> getFileInfo(String path) async {
    try {
      final result =
          await _channelFile.invokeMethod<Map<String, dynamic>>('getInfo', {
        'path': path,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('File info failed: ${e.message}');
      return null;
    }
  }

  // ========== 设备信息 ==========

  /// 获取设备信息
  ///
  /// 返回设备信息 (model, osVersion, deviceId)
  static Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final result =
          await _channelDevice.invokeMethod<Map<String, dynamic>>('getInfo');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Device info failed: ${e.message}');
      return null;
    }
  }

  /// 获取网络状态
  ///
  /// 返回网络类型 (wifi, cellular, none)
  static Future<String?> getNetworkStatus() async {
    try {
      final result =
          await _channelDevice.invokeMethod<String>('getNetworkStatus');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Network status failed: ${e.message}');
      return null;
    }
  }

  /// 获取电池状态
  ///
  /// 返回电池信息 (level, isCharging)
  static Future<Map<String, dynamic>?> getBatteryInfo() async {
    try {
      final result = await _channelDevice
          .invokeMethod<Map<String, dynamic>>('getBatteryInfo');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Battery info failed: ${e.message}');
      return null;
    }
  }

  // ========== 权限管理 ==========

  /// 请求相机权限
  ///
  /// 返回是否获得权限
  static Future<bool> requestCameraPermission() async {
    try {
      final result =
          await _channelDevice.invokeMethod<bool>('requestCameraPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Camera permission request failed: ${e.message}');
      return false;
    }
  }

  /// 请求麦克风权限
  ///
  /// 返回是否获得权限
  static Future<bool> requestMicrophonePermission() async {
    try {
      final result = await _channelDevice
          .invokeMethod<bool>('requestMicrophonePermission');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Microphone permission request failed: ${e.message}');
      return false;
    }
  }

  /// 请求存储权限
  ///
  /// 返回是否获得权限
  static Future<bool> requestStoragePermission() async {
    try {
      final result =
          await _channelDevice.invokeMethod<bool>('requestStoragePermission');
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Storage permission request failed: ${e.message}');
      return false;
    }
  }

  /// 打开应用设置页面
  ///
  /// 用于引导用户手动开启权限
  static Future<void> openAppSettings() async {
    try {
      await _channelDevice.invokeMethod<void>('openAppSettings');
    } on PlatformException catch (e) {
      Logger.error('Open app settings failed: ${e.message}');
    }
  }

  // ========== 剪贴板操作 ==========

  /// 设置剪贴板内容
  ///
  /// [text] 要复制的文本
  static Future<bool> setClipboardText(String text) async {
    try {
      final result = await _channelDevice.invokeMethod<bool>('setClipboard', {
        'text': text,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Set clipboard failed: ${e.message}');
      return false;
    }
  }

  /// 获取剪贴板内容
  ///
  /// 返回剪贴板文本
  static Future<String?> getClipboardText() async {
    try {
      final result = await _channelDevice.invokeMethod<String>('getClipboard');
      return result;
    } on PlatformException catch (e) {
      Logger.error('Get clipboard failed: ${e.message}');
      return null;
    }
  }

  // ========== 认证签名 ==========

  /// 生成认证挑战和签名
  ///
  /// [secretKey] Base64 编码的私钥
  /// 返回 { publicKey, challenge, signature }
  static Future<Map<String, String>?> authChallenge(String secretKey) async {
    try {
      final result = await _channelLibsodium
          .invokeMethod<Map<String, dynamic>>('authChallenge', {
        'secretKey': secretKey,
      });
      if (result == null) {
        Logger.error('Libsodium authChallenge returned null');
        return null;
      }
      return {
        'publicKey': result['publicKey'] as String,
        'challenge': result['challenge'] as String,
        'signature': result['signature'] as String,
      };
    } on PlatformException catch (e) {
      Logger.error('Libsodium authChallenge failed: ${e.message}');
      return null;
    }
  }

  /// 从 secret key 派生公钥
  ///
  /// [secretKey] Base64 编码的私钥
  /// 返回 Base64 编码的公钥
  static Future<String?> getPublicKey(String secretKey) async {
    try {
      final result =
          await _channelLibsodium.invokeMethod<String>('getPublicKey', {
        'secretKey': secretKey,
      });
      return result;
    } on PlatformException catch (e) {
      Logger.error('Libsodium getPublicKey failed: ${e.message}');
      return null;
    }
  }
}
