part of 'encryption_repository.dart';

extension EncryptionRepositoryStorage on EncryptionRepository {
  Future<void> _loadStoredKeys() async {
    try {
      final ownKeyPairJson = await _secureStorage.read(
        key: EncryptionRepository._keyOwnKeyPair,
      );
      if (ownKeyPairJson != null) {
        final json = jsonDecode(ownKeyPairJson) as Map<String, dynamic>;
        _ownKeyPair = KeyPair(
          publicKey: json['publicKey'] as String,
          secretKey: json['secretKey'] as String,
        );
      }

      _serverPublicKey = await _secureStorage.read(
        key: EncryptionRepository._keyServerPublicKey,
      );
      _machineKey = await _secureStorage.read(
        key: EncryptionRepository._keyMachineKey,
      );
      Logger.info(
        'Loaded keys: hasOwnKey=${_ownKeyPair != null}, '
        'hasServerKey=${_serverPublicKey != null}',
      );
    } catch (e) {
      Logger.error('Failed to load stored keys: $e');
    }
  }

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
      await _secureStorage.write(
        key: EncryptionRepository._keyOwnKeyPair,
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

  Future<void> saveServerPublicKey(String publicKey) async {
    _serverPublicKey = publicKey;
    await _secureStorage.write(
      key: EncryptionRepository._keyServerPublicKey,
      value: publicKey,
    );
    Logger.info('Server public key saved');
  }

  Future<void> saveMachineKey(String key) async {
    _machineKey = key;
    await _secureStorage.write(
      key: EncryptionRepository._keyMachineKey,
      value: key,
    );
    Logger.info('Machine key saved');
  }

  Future<void> clearKeys() async {
    _ownKeyPair = null;
    _serverPublicKey = null;
    _machineKey = null;
    await _secureStorage.delete(key: EncryptionRepository._keyOwnKeyPair);
    await _secureStorage.delete(
      key: EncryptionRepository._keyServerPublicKey,
    );
    await _secureStorage.delete(key: EncryptionRepository._keyMachineKey);
    Logger.info('Encryption keys cleared');
  }
}
