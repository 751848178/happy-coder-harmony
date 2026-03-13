import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../domain/encryption_service.dart';
import '../../../harmony/harmony_bridge.dart';
import '../../../shared/utils/extensions.dart';

/// 加密数据仓库
///
/// 处理加密数据的持久化、密钥管理等
class EncryptionRepository {
  EncryptionRepository._() {
    _secureStorage = const FlutterSecureStorage();
  }

  /// 本地存储键
  static const String _keyOwnKeyPair = 'own_key_pair';
  static const String _keyServerPublicKey = 'server_public_key';
  static const String _keyMachineId = 'machine_id';
  static const String _keyMachineKey = 'machine_key';

  late final FlutterSecureStorage _secureStorage;

  /// 密钥对（用户自己的，用于解密）
  KeyPair? _ownKeyPair;

  /// 服务器的公钥（用于加密）
  String? _serverPublicKey;

  /// 机器密钥（用于服务器端加密）
  String? _machineKey;

  /// 获取单例
  static final EncryptionRepository instance = EncryptionRepository._();

  /// 初始化
  Future<void> initialize() async {
    await _loadStoredKeys();
    Logger.info('EncryptionRepository initialized');
  }

  /// 加载存储的密钥
  Future<void> _loadStoredKeys() async {
    try {
      // 加载自己的密钥对
      final ownKeyPairJson = await _secureStorage.read(key: _keyOwnKeyPair);
      if (ownKeyPairJson != null) {
        final json = jsonDecode(ownKeyPairJson) as Map<String, dynamic>;
        _ownKeyPair = KeyPair(
          publicKey: json['publicKey'] as String,
          secretKey: json['secretKey'] as String,
        );
      }

      // 加载服务器公钥
      _serverPublicKey = await _secureStorage.read(key: _keyServerPublicKey);

      // 加载机器密钥
      _machineKey = await _secureStorage.read(key: _keyMachineKey);

      Logger.info('Loaded keys: hasOwnKey=${_ownKeyPair != null}, hasServerKey=${_serverPublicKey != null}');
    } catch (e) {
      Logger.error('Failed to load stored keys: $e');
    }
  }

  /// 生成并保存自己的密钥对
  Future<void> generateAndSaveKeyPair() async {
    try {
      final result = await HarmonyBridge.generateKeyPair();
      if (result == null) {
        throw Exception('Failed to generate key pair from bridge');
      }

      _ownKeyPair = KeyPair(
        publicKey: result['publicKey']!,
        secretKey: result['secretKey']!,
      );

      // 保存到 secure storage
      await _secureStorage.write(
        key: _keyOwnKeyPair,
        value: jsonEncode({
          'publicKey': _ownKeyPair!.publicKey,
          'secretKey': _ownKeyPair!.secretKey,
        }),
      );

      Logger.info('Key pair generated and saved');
    } catch (e) {
      Logger.error('Failed to generate key pair: $e');
      rethrow;
    }
  }

  /// 保存服务器的公钥
  Future<void> saveServerPublicKey(String publicKey) async {
    _serverPublicKey = publicKey;

    await _secureStorage.write(
      key: _keyServerPublicKey,
      value: publicKey,
    );

    Logger.info('Server public key saved');
  }

  /// 保存机器密钥
  Future<void> saveMachineKey(String key) async {
    _machineKey = key;

    await _secureStorage.write(
      key: _keyMachineKey,
      value: key,
    );

    Logger.info('Machine key saved');
  }

  /// 使用自己的密钥加密（用于本地存储的数据）
  Future<String?> encryptWithOwnKey(String data) async {
    if (_ownKeyPair == null) {
      Logger.error('No key pair available');
      return null;
    }

    try {
      final result = await HarmonyBridge.encrypt(data, _ownKeyPair!.secretKey);
      return result;
    } catch (e) {
      Logger.error('Failed to encrypt: $e');
      return null;
    }
  }

  /// 使用自己的私钥解密（用于本地存储的数据）
  Future<String?> decryptWithOwnKey(String encryptedData) async {
    if (_ownKeyPair == null) {
      Logger.error('No key pair available');
      return null;
    }

    try {
      final result = await HarmonyBridge.decrypt(encryptedData, _ownKeyPair!.secretKey);
      return result;
    } catch (e) {
      Logger.error('Failed to decrypt: $e');
      return null;
    }
  }

  /// 使用机器密钥解密（用于服务器端加密的数据）
  Future<String?> decryptWithMachineKey(String encryptedData) async {
    if (_machineKey == null) {
      Logger.error('No machine key available');
      return null;
    }

    try {
      final result = await HarmonyBridge.decrypt(encryptedData, _machineKey!);
      return result;
    } catch (e) {
      Logger.error('Failed to decrypt: $e');
      return null;
    }
  }

  /// 使用公钥加密数据
  ///
  /// 适用于发送给服务器的加密数据
  Future<String?> encryptWithServerKey(String data) async {
    if (_serverPublicKey == null) {
      Logger.error('No server public key available');
      return null;
    }

    try {
      final result = await HarmonyBridge.encryptForPublicKey(
        data,
        _serverPublicKey!,
      );
      return result;
    } catch (e) {
      Logger.error('Failed to encrypt: $e');
      return null;
    }
  }

  /// 检查加密状态
  bool get hasOwnKeyPair => _ownKeyPair != null;
  bool get hasServerPublicKey => _serverPublicKey != null && _serverPublicKey!.isNotEmpty;
  bool get hasMachineKey => _machineKey != null && _machineKey!.isNotEmpty;

  /// 获取自己的公钥
  String? get ownPublicKey => _ownKeyPair?.publicKey;

  /// 清除密钥
  Future<void> clearKeys() async {
    _ownKeyPair = null;
    _serverPublicKey = null;
    _machineKey = null;

    // 清除 secure storage
    await _secureStorage.delete(key: _keyOwnKeyPair);
    await _secureStorage.delete(key: _keyServerPublicKey);
    await _secureStorage.delete(key: _keyMachineKey);

    Logger.info('Encryption keys cleared');
  }
}
