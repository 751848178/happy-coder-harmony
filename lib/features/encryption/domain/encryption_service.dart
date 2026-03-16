import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/encryption_repository.dart';

part 'encryption_models.dart';
part 'encryption_notifier.dart';

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
