part of 'crypto_service.dart';

extension CryptoServiceBoxExtension on CryptoService {
  /// Generate a random key for encryption
  String generateEncryptionKey({int length = 32}) {
    final keyBytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Encode(keyBytes);
  }

  /// Hash data using SHA256
  String hash(String data) {
    final digest = sha256.convert(utf8.encode(data));
    return base64Encode(digest.bytes);
  }

  /// Encrypt data using libsodium crypto_box
  Future<String?> cryptoBox(
    String message,
    String publicKey,
    String secretKey,
  ) async {
    if (HarmonyBridge.isHarmonyOS) {
      try {
        return await HarmonyBridge.encryptForPublicKey(message, publicKey);
      } catch (e) {
        Logger.error('HarmonyBridge encryption failed: $e');
        return null;
      }
    }

    Logger.warning('cryptoBox not supported on non-HarmonyOS');
    return null;
  }

  /// Decrypt data using libsodium crypto_box_open_easy
  Future<String?> cryptoBoxOpenEasy(
    String encryptedData,
    String secretKey,
  ) async {
    if (HarmonyBridge.isHarmonyOS) {
      try {
        return await HarmonyBridge.decryptFromPublicKey(
          encryptedData,
          secretKey,
        );
      } catch (e) {
        Logger.error('HarmonyBridge decryption failed: $e');
        return null;
      }
    }

    Logger.warning('cryptoBoxOpenEasy not supported on non-HarmonyOS');
    return null;
  }

  /// Encrypt data using libsodium crypto_box_easy-compatible bundle
  Future<Uint8List> encryptBoxBundle(
    Uint8List message,
    Uint8List recipientPublicKey,
  ) async {
    final ephemeralPrivateKey = nacl.PrivateKey.generate();
    final recipientKey = nacl.PublicKey(recipientPublicKey);
    final box = nacl_public.Box(
      myPrivateKey: ephemeralPrivateKey,
      theirPublicKey: recipientKey,
    );
    final encrypted = box.encrypt(message);
    final ephPublicKeyBytes = Uint8List.fromList(ephemeralPrivateKey.publicKey);
    final nonceBytes = Uint8List.fromList(encrypted.nonce);
    final cipherBytes = Uint8List.fromList(encrypted.cipherText);

    return Uint8List(
      ephPublicKeyBytes.length + nonceBytes.length + cipherBytes.length,
    )
      ..setAll(0, ephPublicKeyBytes)
      ..setAll(ephPublicKeyBytes.length, nonceBytes)
      ..setAll(ephPublicKeyBytes.length + nonceBytes.length, cipherBytes);
  }
}
