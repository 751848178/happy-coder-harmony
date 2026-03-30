import 'dart:convert';

import '../../../shared/models/auth_models.dart';
import '../../../shared/platform/platform_storage.dart';

/// Token 存储服务
///
/// 封装 secure storage 操作，提供类型安全的读写接口
/// 使用 PlatformStorage 实现 HarmonyOS 兼容性
class TokenStorageService {
  TokenStorageService._();

  /// 获取单例
  static final TokenStorageService instance = TokenStorageService._();

  final _storage = PlatformStorage.instance;

  /// 存储键
  static const String _keyToken = 'auth_token';
  static const String _keyMachineId = 'machine_id';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyEncryptionType = 'encryption_type';
  static const String _keyPublicKey = 'public_key';
  static const String _keyMachineKey = 'machine_key';
  static const String _keySecret = 'secret';
  static const String _keyUser = 'user_data';
  static const String _keyBackupId = 'backup_id';

  /// 存储 Token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// 读取 Token
  Future<String?> getToken() async {
    try {
      return await _storage.read(_keyToken);
    } catch (e) {
      throw Exception('Failed to read token: $e');
    }
  }

  /// 删除 Token
  Future<void> deleteToken() async {
    try {
      await _storage.delete(_keyToken);
    } catch (e) {
      throw Exception('Failed to delete token: $e');
    }
  }

  /// 保存机器 ID
  Future<void> saveMachineId(String machineId) async {
    await _storage.write(key: _keyMachineId, value: machineId);
  }

  /// 读取机器 ID
  Future<String> getMachineId() async {
    final id = await _storage.read(_keyMachineId);
    return id ?? '';
  }

  /// 保存加密密钥
  Future<void> saveEncryptionKey(String key) async {
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  /// 读取加密密钥
  Future<String?> getEncryptionKey() async {
    return await _storage.read(_keyEncryptionKey);
  }

  /// 保存加密类型
  Future<void> saveEncryptionType(EncryptionType type) async {
    await _storage.write(key: _keyEncryptionType, value: type.name);
  }

  /// 读取加密类型
  Future<EncryptionType> getEncryptionType() async {
    final type = await _storage.read(_keyEncryptionType);
    return EncryptionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => EncryptionType.legacy,
    );
  }

  /// 保存公钥
  Future<void> savePublicKey(String publicKey) async {
    await _storage.write(key: _keyPublicKey, value: publicKey);
  }

  /// 读取公钥
  Future<String?> getPublicKey() async {
    return await _storage.read(_keyPublicKey);
  }

  /// 保存机器密钥
  Future<void> saveMachineKey(String key) async {
    await _storage.write(key: _keyMachineKey, value: key);
  }

  /// 读取机器密钥
  Future<String?> getMachineKey() async {
    return await _storage.read(_keyMachineKey);
  }

  /// 读取 Happy 账户 secret
  Future<String?> getSecretKey() async {
    return await _storage.read(_keySecret);
  }

  /// 保存用户信息
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toMap());
    await _storage.write(key: _keyUser, value: userJson);
  }

  /// 读取用户信息
  Future<User?> getUser() async {
    final userJson = await _storage.read(_keyUser);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  /// 保存备份 ID
  Future<void> saveBackupId(String backupId) async {
    await _storage.write(key: _keyBackupId, value: backupId);
  }

  /// 读取备份 ID
  Future<String?> getBackupId() async {
    return await _storage.read(_keyBackupId);
  }

  /// 通用写入方法（用于测试）
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// 通用读取方法（用于测试）
  Future<String?> read(String key) async {
    return await _storage.read(key);
  }

  /// 通用删除方法（用于测试）
  Future<void> delete(String key) async {
    await _storage.delete(key);
  }

  /// 清除所有认证数据
  Future<void> clearAll() async {
    await deleteToken();
    await _storage.delete(_keyMachineId);
    await _storage.delete(_keyEncryptionKey);
    await _storage.delete(_keyEncryptionType);
    await _storage.delete(_keyPublicKey);
    await _storage.delete(_keyMachineKey);
    await _storage.delete(_keySecret);
    await _storage.delete(_keyUser);
    await _storage.delete(_keyBackupId);
  }
}
