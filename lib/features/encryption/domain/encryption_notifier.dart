part of 'encryption_service.dart';

/// 加密 Notifier
///
/// 处理加密相关状态
class EncryptionNotifier extends StateNotifier<EncryptionState> {
  EncryptionNotifier(this._repository) : super(EncryptionState.initial);

  final EncryptionRepository _repository;

  /// 初始化
  Future<void> initialize() async {
    state = EncryptionState.encrypting(true);

    try {
      await _repository.initialize();

      if (_repository.hasOwnKeyPair) {
        state = EncryptionState.hasKeys();
      } else {
        state = EncryptionState.initial;
      }
    } catch (e) {
      state = EncryptionState.error('初始化失败: ${e.toString()}');
    }
  }

  /// 生成密钥对
  Future<void> generateKeyPair() async {
    state = EncryptionState.encrypting(true);

    try {
      await _repository.generateAndSaveKeyPair();
      state = EncryptionState.hasKeys();
    } catch (e) {
      state = EncryptionState.error('生成密钥对失败: ${e.toString()}');
    }
  }

  /// 加密数据（使用自己的密钥或服务器密钥）
  Future<void> encrypt(String data, {bool isOwnKey = false}) async {
    state = EncryptionState.encrypting(isOwnKey);

    try {
      final result = await (isOwnKey
          ? _repository.encryptWithOwnKey(data)
          : _repository.encryptWithServerKey(data));
      if (result != null) {
        state = EncryptionState.decrypted(result);
      } else {
        state = EncryptionState.error('加密失败: 结果为空');
      }
    } catch (e) {
      state = EncryptionState.error('加密失败: ${e.toString()}');
    }
  }

  /// 解密数据
  Future<void> decrypt(String data, {bool isOwnKey = false}) async {
    state = EncryptionState.encrypting(isOwnKey);

    try {
      final result = await (isOwnKey
          ? _repository.decryptWithOwnKey(data)
          : _repository.decryptWithMachineKey(data));
      if (result != null) {
        state = EncryptionState.decrypted(result);
      } else {
        state = EncryptionState.error('解密失败: 结果为空');
      }
    } catch (e) {
      state = EncryptionState.error('解密失败: ${e.toString()}');
    }
  }

  /// 清除密钥对
  Future<void> clearKeyPair() async {
    state = EncryptionState.encrypting(true);

    try {
      await _repository.clearKeys();
      state = EncryptionState.initial;
    } catch (e) {
      state = EncryptionState.error('清除密钥对失败: ${e.toString()}');
    }
  }

  /// 清除所有密钥
  Future<void> clearAllKeys() async {
    state = EncryptionState.encrypting(true);

    try {
      await _repository.clearKeys();
      state = EncryptionState.initial;
    } catch (e) {
      state = EncryptionState.error('清除密钥失败: ${e.toString()}');
    }
  }

  /// 清除密钥（别名方法）
  Future<void> clearKeys() async => clearAllKeys();
}
