import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../harmony/harmony_bridge.dart';
import '../../../shared/utils/extensions.dart';
import '../domain/encryption_service.dart';

part 'encryption_repository_storage.dart';

class EncryptionRepository {
  EncryptionRepository._() {
    _secureStorage = const FlutterSecureStorage();
  }

  static const String _keyOwnKeyPair = 'own_key_pair';
  static const String _keyServerPublicKey = 'server_public_key';
  static const String _keyMachineKey = 'machine_key';

  static final EncryptionRepository instance = EncryptionRepository._();

  late final FlutterSecureStorage _secureStorage;
  KeyPair? _ownKeyPair;
  String? _serverPublicKey;
  String? _machineKey;

  Future<void> initialize() async {
    await _loadStoredKeys();
    Logger.info('EncryptionRepository initialized');
  }

  Future<String?> encryptWithOwnKey(String data) async {
    if (_ownKeyPair == null) {
      Logger.error('No key pair available');
      return null;
    }
    return _runCrypto(
        () => HarmonyBridge.encrypt(data, _ownKeyPair!.secretKey));
  }

  Future<String?> decryptWithOwnKey(String encryptedData) async {
    if (_ownKeyPair == null) {
      Logger.error('No key pair available');
      return null;
    }
    return _runCrypto(
      () => HarmonyBridge.decrypt(encryptedData, _ownKeyPair!.secretKey),
    );
  }

  Future<String?> decryptWithMachineKey(String encryptedData) async {
    if (_machineKey == null) {
      Logger.error('No machine key available');
      return null;
    }
    return _runCrypto(() => HarmonyBridge.decrypt(encryptedData, _machineKey!));
  }

  Future<String?> encryptWithServerKey(String data) async {
    if (_serverPublicKey == null) {
      Logger.error('No server public key available');
      return null;
    }
    return _runCrypto(
      () => HarmonyBridge.encryptForPublicKey(data, _serverPublicKey!),
    );
  }

  bool get hasOwnKeyPair => _ownKeyPair != null;
  bool get hasServerPublicKey =>
      _serverPublicKey != null && _serverPublicKey!.isNotEmpty;
  bool get hasMachineKey => _machineKey != null && _machineKey!.isNotEmpty;
  String? get ownPublicKey => _ownKeyPair?.publicKey;

  Future<String?> _runCrypto(Future<String?> Function() action) async {
    try {
      return await action();
    } catch (e) {
      Logger.error('Failed to run crypto operation: $e');
      return null;
    }
  }
}
