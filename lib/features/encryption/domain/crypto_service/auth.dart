part of 'crypto_service.dart';

extension CryptoServiceAuthExtension on CryptoService {
  /// Generate auth challenge and signature
  ///
  /// [secretKey] Base64 encoded secret key (Ed25519 secret key, 64 bytes)
  /// Returns { publicKey, challenge, signature }
  Future<Map<String, String>> authChallenge(String secretKey) async {
    if (HarmonyBridge.isHarmonyOS) {
      try {
        final result = await HarmonyBridge.authChallenge(secretKey);
        if (result != null) {
          return {
            'publicKey': result['publicKey'] as String,
            'challenge': result['challenge'] as String,
            'signature': result['signature'] as String,
          };
        }
      } catch (e) {
        Logger.warning('HarmonyBridge authChallenge failed: $e');
      }
    }

    Logger.info('=== authChallenge START ===');
    Logger.info('Secret key length: ${secretKey.length}');

    final secretKeyBytes = base64Decode(secretKey);
    Logger.info('Secret key decoded: ${secretKeyBytes.length} bytes');
    if (secretKeyBytes.length < 32) {
      throw Exception(
        'Secret key too short: ${secretKeyBytes.length} bytes (expected 32-64 bytes)',
      );
    }

    final seedBytes = secretKeyBytes.sublist(0, 32);
    if (!HarmonyBridge.isHarmonyOS) {
      final sodium = await _trySodium();
      if (sodium != null) {
        final seed = SecureKey.fromList(sodium, Uint8List.fromList(seedBytes));
        final keyPair = sodium.crypto.sign.seedKeyPair(seed);
        final publicKey = base64Encode(keyPair.publicKey);
        final challengeBytes = sodium.randombytes.buf(32);
        final challenge = base64Encode(challengeBytes);
        final signature = sodium.crypto.sign.detached(
          message: challengeBytes,
          secretKey: keyPair.secretKey,
        );
        final signatureBase64 = base64Encode(signature);

        Logger.info('Derived public key: ${publicKey.substring(0, 16)}...');
        Logger.info(
            'Generated challenge (Base64): ${challenge.substring(0, 32)}...');
        Logger.info(
            'Generated signature: ${signatureBase64.substring(0, 32)}...');
        Logger.info('Sending to server:');
        Logger.info('  publicKey: $publicKey');
        Logger.info('  challenge: $challenge');
        Logger.info('  signature: $signatureBase64');

        return {
          'publicKey': publicKey,
          'challenge': challenge,
          'signature': signatureBase64,
        };
      }
    }

    Logger.info('Sodium unavailable; using pure Dart Ed25519 fallback');
    final keyPair = await CryptoService._ed25519.newKeyPairFromSeed(seedBytes);
    final publicKey = await keyPair.extractPublicKey();
    final challengeBytes = _randomBytes(32);
    final challenge = base64Encode(challengeBytes);
    final signature = await CryptoService._ed25519.sign(
      challengeBytes,
      keyPair: keyPair,
    );
    final signatureBase64 = base64Encode(signature.bytes);

    Logger.info(
      'Derived public key: ${base64Encode(publicKey.bytes).substring(0, 16)}...',
    );
    Logger.info(
        'Generated challenge (Base64): ${challenge.substring(0, 32)}...');
    Logger.info('Generated signature: ${signatureBase64.substring(0, 32)}...');

    return {
      'publicKey': base64Encode(publicKey.bytes),
      'challenge': challenge,
      'signature': signatureBase64,
    };
  }

  /// Sign a message using Ed25519
  Future<String> sign(String message, String secretKey) async {
    final messageBytes = utf8.encode(message);
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
      final keyPair = sodium.crypto.sign.seedKeyPair(seed);
      final signature = sodium.crypto.sign.detached(
        message: Uint8List.fromList(messageBytes),
        secretKey: keyPair.secretKey,
      );
      return base64Encode(signature);
    }

    final keyPair = await CryptoService._ed25519.newKeyPairFromSeed(
      secretKeyBytes.sublist(0, 32),
    );
    final signature = await CryptoService._ed25519.sign(
      messageBytes,
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  /// Verify a signature using Ed25519
  Future<bool> verify(
      String message, String signature, String publicKey) async {
    final messageBytes = utf8.encode(message);
    final publicKeyBytes = base64Decode(publicKey);
    final signatureBytes = base64Decode(signature);

    final sodium = await _trySodium();
    if (sodium != null) {
      return sodium.crypto.sign.verifyDetached(
        message: messageBytes,
        signature: signatureBytes,
        publicKey: publicKeyBytes,
      );
    }

    final key = cryptography.SimplePublicKey(
      publicKeyBytes,
      type: cryptography.KeyPairType.ed25519,
    );
    final sig = cryptography.Signature(signatureBytes, publicKey: key);
    return CryptoService._ed25519.verify(messageBytes, signature: sig);
  }
}
