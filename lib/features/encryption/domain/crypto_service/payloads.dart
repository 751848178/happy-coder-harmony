part of 'crypto_service.dart';

extension CryptoServicePayloadExtension on CryptoService {
  /// Decrypt Happy Coder's encrypted per-session data key.
  Future<Uint8List?> decryptHappyCoderDataEncryptionKey(
    String encryptedBase64,
    String secretKey,
  ) async {
    final encryptedBytes = CryptoService.decodeBase64Flexible(encryptedBase64);
    if (encryptedBytes.isEmpty || encryptedBytes.first != 0) {
      return null;
    }

    final masterSecret = CryptoService.decodeBase64Flexible(secretKey);
    if (masterSecret.length < 32) {
      throw Exception(
        'Secret key too short: ${masterSecret.length} bytes (expected at least 32 bytes)',
      );
    }

    final normalizedSecret = Uint8List.fromList(masterSecret.sublist(0, 32));
    final contentSeed = _deriveHappyCoderKey(
      normalizedSecret,
      'Happy EnCoder',
      const ['content'],
    );
    final contentPrivateKey = nacl.PrivateKey.fromSeed(contentSeed);
    final payload = encryptedBytes.sublist(1);
    if (payload.length < 56) {
      return null;
    }

    final ephemeralPublicKey = nacl.PublicKey(payload.sublist(0, 32));
    final encryptedMessage = nacl.EncryptedMessage(
      nonce: payload.sublist(32, 56),
      cipherText: payload.sublist(56),
    );

    try {
      final box = nacl_public.Box(
        myPrivateKey: contentPrivateKey,
        theirPublicKey: ephemeralPublicKey,
      );
      return Uint8List.fromList(box.decrypt(encryptedMessage));
    } catch (e) {
      Logger.warning('Failed to decrypt Happy session key: $e');
      return null;
    }
  }

  /// Decrypt Happy Coder AES-GCM JSON payload.
  Future<dynamic> decryptHappyCoderAesGcmJson(
    String encryptedBase64,
    Uint8List secretKey,
  ) async {
    final encryptedBytes = CryptoService.decodeBase64Flexible(encryptedBase64);
    if (encryptedBytes.isEmpty || encryptedBytes.first != 0) {
      return null;
    }

    final payload = encryptedBytes.sublist(1);
    if (payload.length < 28) {
      return null;
    }

    final nonce = payload.sublist(0, 12);
    final cipherWithMac = payload.sublist(12);
    if (cipherWithMac.length < 16) {
      return null;
    }

    final cipherText = cipherWithMac.sublist(0, cipherWithMac.length - 16);
    final macBytes = cipherWithMac.sublist(cipherWithMac.length - 16);

    try {
      final algorithm = cryptography.AesGcm.with256bits();
      final clearBytes = await algorithm.decrypt(
        cryptography.SecretBox(
          cipherText,
          nonce: nonce,
          mac: cryptography.Mac(macBytes),
        ),
        secretKey: cryptography.SecretKey(secretKey),
      );
      return jsonDecode(utf8.decode(clearBytes));
    } catch (e) {
      Logger.warning('Failed to decrypt Happy AES-GCM payload: $e');
      return null;
    }
  }

  /// Encrypt Happy Coder AES-GCM JSON payload.
  Future<String> encryptHappyCoderAesGcmJson(
    Object payload,
    Uint8List secretKey,
  ) async {
    final clearBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final nonce = _randomBytes(12);
    final algorithm = cryptography.AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      clearBytes,
      secretKey: cryptography.SecretKey(secretKey),
      nonce: nonce,
    );

    final encoded = Uint8List(
      1 +
          nonce.length +
          secretBox.cipherText.length +
          secretBox.mac.bytes.length,
    )
      ..[0] = 0
      ..setAll(1, nonce)
      ..setAll(1 + nonce.length, secretBox.cipherText)
      ..setAll(
          1 + nonce.length + secretBox.cipherText.length, secretBox.mac.bytes);
    return base64Encode(encoded);
  }

  /// Encrypt Happy Coder legacy secretbox JSON payload.
  Future<String> encryptHappyCoderLegacyJson(
    Object payload,
    String secretKey,
  ) async {
    final masterSecret = CryptoService.decodeBase64Flexible(secretKey);
    if (masterSecret.length < 32) {
      throw Exception(
        'Secret key too short: ${masterSecret.length} bytes (expected at least 32 bytes)',
      );
    }

    final box = nacl_secret.SecretBox(
      Uint8List.fromList(masterSecret.sublist(0, 32)),
    );
    final encrypted = box.encrypt(
      Uint8List.fromList(utf8.encode(jsonEncode(payload))),
    );
    return base64Encode(encrypted.toUint8List());
  }

  /// Decrypt Happy Coder legacy secretbox JSON payload.
  Future<dynamic> decryptHappyCoderLegacyJson(
    String encryptedBase64,
    String secretKey,
  ) async {
    final encryptedBytes = CryptoService.decodeBase64Flexible(encryptedBase64);
    if (encryptedBytes.isEmpty) {
      return null;
    }

    final masterSecret = CryptoService.decodeBase64Flexible(secretKey);
    if (masterSecret.length < 32) {
      throw Exception(
        'Secret key too short: ${masterSecret.length} bytes (expected at least 32 bytes)',
      );
    }

    final box = nacl_secret.SecretBox(
      Uint8List.fromList(masterSecret.sublist(0, 32)),
    );
    try {
      final decrypted =
          box.decrypt(nacl.EncryptedMessage.fromList(encryptedBytes));
      return jsonDecode(utf8.decode(decrypted));
    } catch (e) {
      Logger.warning('Failed to decrypt Happy legacy payload: $e');
      return null;
    }
  }
}
