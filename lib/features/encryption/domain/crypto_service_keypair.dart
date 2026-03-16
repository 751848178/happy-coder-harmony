part of 'crypto_service.dart';

extension CryptoServiceKeypairExtension on CryptoService {
  /// Generate a signing key pair using Ed25519
  ///
  /// Returns { publicKey, secretKey, seed } in Base64 encoding
  Future<Map<String, String>> generateKeyPair() async {
    if (HarmonyBridge.isHarmonyOS) {
      try {
        final result = await HarmonyBridge.generateKeyPair();
        if (result != null) {
          return {
            'publicKey': result['publicKey'] as String,
            'secretKey': result['secretKey'] as String,
            'seed': result['secretKey'] as String,
          };
        }
      } catch (e) {
        Logger.error('HarmonyBridge keypair generation failed: $e');
      }
    }

    final sodium = await _trySodium();
    if (sodium != null) {
      final keyPair = sodium.crypto.sign.keyPair();
      final secretKeyBytes = keyPair.secretKey.extractBytes();
      return {
        'publicKey': base64Encode(keyPair.publicKey),
        'secretKey': base64Encode(secretKeyBytes),
        'seed': base64Encode(secretKeyBytes.sublist(0, 32)),
      };
    }

    Logger.info('Sodium unavailable; generating keypair via pure Dart Ed25519');
    final keyPair = await CryptoService._ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    return {
      'publicKey': base64Encode(publicKey.bytes),
      'secretKey': base64Encode(privateKey),
      'seed': base64Encode(privateKey),
    };
  }

  /// Derive public key from secret key (Ed25519)
  Future<String> getPublicKey(String secretKey) async {
    if (HarmonyBridge.isHarmonyOS) {
      try {
        final result = await HarmonyBridge.getPublicKey(secretKey);
        if (result != null) {
          return result;
        }
      } catch (e) {
        Logger.warning('HarmonyBridge public key derivation failed: $e');
      }
    }

    final secretKeyBytes = base64Decode(secretKey);
    if (secretKeyBytes.length < 32) {
      throw Exception(
        'Secret key too short: ${secretKeyBytes.length} bytes (expected 32-64 bytes)',
      );
    }

    final sodium = await _trySodium();
    if (sodium != null) {
      final seed = SecureKey.fromList(
        sodium,
        Uint8List.fromList(secretKeyBytes.sublist(0, 32)),
      );
      return base64Encode(sodium.crypto.sign.seedKeyPair(seed).publicKey);
    }

    Logger.info(
        'Sodium unavailable; deriving public key via pure Dart Ed25519');
    final keyPair = await CryptoService._ed25519.newKeyPairFromSeed(
      secretKeyBytes.sublist(0, 32),
    );
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }
}
