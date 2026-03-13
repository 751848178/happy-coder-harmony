import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/encryption_repository.dart';
import '../../../shared/utils/extensions.dart';

/// 密钥对模型
class KeyPair {
  final String publicKey;
  final String secretKey;

  const KeyPair({
    required this.publicKey,
    required this.secretKey,
  });

  factory KeyPair.fromJson(Map<String, dynamic> json) {
    return KeyPair(
      publicKey: json['publicKey'] as String? ?? '',
      secretKey: json['secretKey'] as String? ?? '',
    );
  }
}

/// 加密状态
class EncryptionState {
  const EncryptionState._();

  static const EncryptionState initial = EncryptionState._();

  static EncryptionState hasKeys() => const _HasKeysState();
  static EncryptionState encrypting(bool isOwnKey) => _EncryptingState(isOwnKey);
  static EncryptionState decrypted(String data) => _DecryptedState(data);
  static EncryptionState error(String message) => _EncryptionErrorState(message);

  String? get decryptedData => this is _DecryptedState
      ? (this as _DecryptedState).data
      : null;

  bool get isEncrypting => this is _EncryptingState;
  bool get isInitial => this is EncryptionState;
  bool get isHasKeys => this is _HasKeysState;
  bool get isDecrypted => this is _DecryptedState;
  bool get isError => this is _EncryptionErrorState;
  String? get errorMessage => this is _EncryptionErrorState
      ? (this as _EncryptionErrorState).message
      : null;
  bool get isOwnKeyEncrypting => this is _EncryptingState
      ? (this as _EncryptingState).isOwnKey
      : false;
}

class _HasKeysState extends EncryptionState {
  const _HasKeysState() : super._();
}

class _EncryptingState extends EncryptionState {
  final bool isOwnKey;

  const _EncryptingState(this.isOwnKey) : super._();
}

class _DecryptedState extends EncryptionState {
  final String data;

  const _DecryptedState(this.data) : super._();
}

class _EncryptionErrorState extends EncryptionState {
  final String message;

  const _EncryptionErrorState(this.message) : super._();
}

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

/// 加密服务
///
/// 提供加密相关的服务
class EncryptionService {
  EncryptionService(this._repository);

  final EncryptionRepository _repository;

  /// 初始化
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// 是否有密钥对
  bool get hasKeyPair => _repository.hasOwnKeyPair;

  /// 获取公钥
  String? get publicKey => _repository.ownPublicKey;

  /// 加密数据
  Future<String?> encrypt(String data, {bool isOwnKey = false}) async {
    return isOwnKey
        ? _repository.encryptWithOwnKey(data)
        : _repository.encryptWithServerKey(data);
  }

  /// 解密数据
  Future<String?> decrypt(String data, {bool isOwnKey = false}) async {
    return isOwnKey
        ? _repository.decryptWithOwnKey(data)
        : _repository.decryptWithMachineKey(data);
  }
}
