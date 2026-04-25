part of 'crypto_service.dart';

extension CryptoServiceLinkExtension on CryptoService {
  /// Derive Happy Coder content public key from account secret.
  Future<Uint8List> deriveHappyCoderContentPublicKey(String secretKey) async {
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
    return Uint8List.fromList(contentPrivateKey.publicKey);
  }

  /// Generate QR auth key pair for Happy Coder link account
  Future<Map<String, dynamic>> generateQRAuthKeyPair() async {
    final keyPair = await generateKeyPair();
    final publicKey = keyPair['publicKey'] as String;
    final qrData =
        'happy:///account?${CryptoService.base64UrlEncode(publicKey)}';
    return {
      'publicKey': publicKey,
      'secretKey': keyPair['secretKey'] as String,
      'qrData': qrData,
    };
  }

  /// Encrypt data specifically for Happy Coder link account approval
  Future<String?> cryptoBoxForLink(
    String message,
    String publicKey,
    String secretKey,
  ) async {
    return cryptoBox(message, publicKey, secretKey);
  }

  /// Decrypt data specifically for Happy Coder link account approval response
  Future<String?> cryptoBoxForLinkApproval(
    String encryptedData,
    String secretKey,
  ) async {
    return cryptoBoxOpenEasy(encryptedData, secretKey);
  }
}
