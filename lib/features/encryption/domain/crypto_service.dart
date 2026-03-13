import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:pinenacl/api.dart' as nacl;
import 'package:pinenacl/src/authenticated_encryption/public.dart'
    as nacl_public;
import 'package:pinenacl/src/authenticated_encryption/secret.dart'
    as nacl_secret;
import 'package:sodium_libs/sodium_libs.dart';

import '../../../shared/utils/extensions.dart';
import '../../../harmony/harmony_bridge.dart';

/// Crypto Service
///
/// Provides cryptographic operations for authentication.
/// Uses libsodium for HarmonyOS when available.
/// Implements Ed25519 signing like Happy Coder project.
class CryptoService {
  CryptoService._();

  static CryptoService? _instance;
  final _random = math.Random.secure();
  static final _ed25519 = cryptography.Ed25519();

  /// Sodium instance - initialized lazily
  static Sodium? _sodiumInstance;

  static Future<CryptoService> get instance async {
    if (_instance != null) return _instance!;
    _instance = CryptoService._();
    return _instance!;
  }

  /// Get or initialize Sodium instance
  static Future<Sodium> get _sodium async {
    // Check HarmonyOS first
    if (HarmonyBridge.isHarmonyOS) {
      throw Exception('Sodium libs not available on HarmonyOS');
    }

    if (_sodiumInstance == null) {
      // Use sodium_libs for Flutter platform-specific loading
      _sodiumInstance = await SodiumInit.init();
    }
    return _sodiumInstance!;
  }

  /// Generate a signing key pair using Ed25519
  ///
  /// Returns { publicKey, secretKey, seed } in Base64 encoding
  Future<Map<String, String>> generateKeyPair() async {
    // Try HarmonyBridge first for HarmonyOS
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

    // Prefer sodium when available
    final sodium = await _trySodium();
    if (sodium != null) {
      final keyPair = sodium.crypto.sign.keyPair();

      // Extract bytes - public key is already Uint8List
      final publicKeyBytes = keyPair.publicKey;
      // Secret key needs to be extracted from SecureKey
      final secretKeyBytes = keyPair.secretKey.extractBytes();

      // Ed25519 secret key is 64 bytes: first 32 bytes is seed
      final seed = base64Encode(secretKeyBytes.sublist(0, 32));

      return {
        'publicKey': base64Encode(publicKeyBytes),
        'secretKey': base64Encode(secretKeyBytes),
        'seed': seed,
      };
    }

    // Fallback to pure Dart Ed25519 (works on HarmonyOS without libsodium)
    Logger.info('Sodium unavailable; generating keypair via pure Dart Ed25519');
    final keyPair = await _ed25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    return {
      'publicKey': base64Encode(publicKey.bytes),
      // Use seed/private bytes as secretKey (32 bytes). Existing flows derive public from first 32 bytes.
      'secretKey': base64Encode(privateKey),
      'seed': base64Encode(privateKey),
    };
  }

  /// Derive public key from secret key (Ed25519)
  ///
  /// [secretKey] Base64 encoded secret key (or seed)
  Future<String> getPublicKey(String secretKey) async {
    // Try HarmonyBridge first
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
          'Secret key too short: ${secretKeyBytes.length} bytes (expected 32-64 bytes)');
    }

    // Use sodium when available
    final sodium = await _trySodium();
    if (sodium != null) {
      final seed = SecureKey.fromList(
        sodium,
        Uint8List.fromList(secretKeyBytes.sublist(0, 32)),
      );
      final publicKeyBytes = sodium.crypto.sign.seedKeyPair(seed).publicKey;
      return base64Encode(publicKeyBytes);
    }

    // Fallback to pure Dart Ed25519
    Logger.info(
        'Sodium unavailable; deriving public key via pure Dart Ed25519');
    final keyPair =
        await _ed25519.newKeyPairFromSeed(secretKeyBytes.sublist(0, 32));
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// Generate auth challenge and signature
  ///
  /// [secretKey] Base64 encoded secret key (Ed25519 secret key, 64 bytes)
  /// Returns { publicKey, challenge, signature }
  Future<Map<String, String>> authChallenge(String secretKey) async {
    // Try HarmonyBridge first
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
          'Secret key too short: ${secretKeyBytes.length} bytes (expected 32-64 bytes)');
    }

    final seedBytes = secretKeyBytes.sublist(0, 32);

    // Prefer sodium on supported platforms
    if (!HarmonyBridge.isHarmonyOS) {
      final sodium = await _trySodium();
      if (sodium != null) {
        final seed = SecureKey.fromList(sodium, Uint8List.fromList(seedBytes));
        final keyPair = sodium.crypto.sign.seedKeyPair(seed);
        final publicKeyBytes = keyPair.publicKey;

        final publicKey = base64Encode(publicKeyBytes);
        Logger.info('Derived public key: ${publicKey.substring(0, 16)}...');

        // Generate 32-byte random challenge
        final challengeBytes = sodium.randombytes.buf(32);
        final challenge = base64Encode(challengeBytes);
        Logger.info(
            'Generated challenge (Base64): ${challenge.substring(0, 32)}...');

        // Sign challenge using Ed25519 detached signature
        final signature = sodium.crypto.sign.detached(
          message: challengeBytes,
          secretKey: keyPair.secretKey,
        );
        final signatureBase64 = base64Encode(signature);
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

    // Fallback to pure Dart Ed25519 (works on HarmonyOS without sodium_libs)
    Logger.info('Sodium unavailable; using pure Dart Ed25519 fallback');
    final keyPair = await _ed25519.newKeyPairFromSeed(seedBytes);
    final publicKey = await keyPair.extractPublicKey();
    final challengeBytes = _randomBytes(32);
    final challenge = base64Encode(challengeBytes);
    final signature = await _ed25519.sign(
      challengeBytes,
      keyPair: keyPair,
    );
    final signatureBase64 = base64Encode(signature.bytes);

    Logger.info(
        'Derived public key: ${base64Encode(publicKey.bytes).substring(0, 16)}...');
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
  ///
  /// [message] The message to sign
  /// [secretKey] Base64 encoded Ed25519 secret key
  Future<String> sign(String message, String secretKey) async {
    final messageBytes = utf8.encode(message);
    final secretKeyBytes = base64Decode(secretKey);
    if (secretKeyBytes.length < 32) {
      throw Exception(
          'Secret key too short: ${secretKeyBytes.length} bytes (expected 32-64 bytes)');
    }

    // Prefer sodium if available
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

    // Fallback to pure Dart Ed25519
    final keyPair =
        await _ed25519.newKeyPairFromSeed(secretKeyBytes.sublist(0, 32));
    final signature = await _ed25519.sign(
      messageBytes,
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  /// Verify a signature using Ed25519
  ///
  /// Returns true if signature is valid
  Future<bool> verify(
      String message, String signature, String publicKey) async {
    final messageBytes = utf8.encode(message);
    final publicKeyBytes = base64Decode(publicKey);
    final signatureBytes = base64Decode(signature);

    final sodium = await _trySodium();
    if (sodium != null) {
      final isValid = sodium.crypto.sign.verifyDetached(
        message: messageBytes,
        signature: signatureBytes,
        publicKey: publicKeyBytes,
      );
      return isValid;
    }

    final key = cryptography.SimplePublicKey(
      publicKeyBytes,
      type: cryptography.KeyPairType.ed25519,
    );
    final sig = cryptography.Signature(
      signatureBytes,
      publicKey: key,
    );
    return _ed25519.verify(
      messageBytes,
      signature: sig,
    );
  }

  /// Try initializing sodium libs, returns null if unavailable.
  Future<Sodium?> _trySodium() async {
    try {
      return await _sodium;
    } on Error catch (e) {
      Logger.warning('Sodium init error: $e');
      return null;
    } catch (e) {
      Logger.warning('Sodium init failed: $e');
      return null;
    }
  }

  Uint8List _randomBytes(int length) {
    final buffer = Uint8List(length);
    for (var i = 0; i < length; i++) {
      buffer[i] = _random.nextInt(256);
    }
    return buffer;
  }

  /// Generate a random key for encryption
  ///
  /// [length] Key length in bytes (default 32 for AES-256)
  String generateEncryptionKey({int length = 32}) {
    final keyBytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Encode(keyBytes);
  }

  /// Hash data using SHA256
  ///
  /// [data] The data to hash
  /// Returns Base64 encoded hash
  String hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  /// Encrypt data using libsodium crypto_box
  ///
  /// [message] The message to encrypt (Base64 encoded secret)
  /// [publicKey] The recipient's public key (Base64 encoded)
  /// [secretKey] The sender's secret key (Base64 encoded)
  ///
  /// Returns Base64 encrypted data or null on failure
  Future<String?> cryptoBox(
      String message, String publicKey, String secretKey) async {
    // Try HarmonyBridge first
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
  ///
  /// [encryptedData] Base64 encrypted data (nonce + ciphertext)
  /// [secretKey] The recipient's secret key (Base64 encoded)
  ///
  /// Returns decrypted data as Base64 string, or null on failure
  Future<String?> cryptoBoxOpenEasy(
      String encryptedData, String secretKey) async {
    // Try HarmonyBridge first
    if (HarmonyBridge.isHarmonyOS) {
      try {
        return await HarmonyBridge.decryptFromPublicKey(
            encryptedData, secretKey);
      } catch (e) {
        Logger.error('HarmonyBridge decryption failed: $e');
        return null;
      }
    }

    Logger.warning('cryptoBoxOpenEasy not supported on non-HarmonyOS');
    return null;
  }

  /// Encrypt data using libsodium crypto_box_easy-compatible bundle
  ///
  /// Bundle format: [ephemeralPublicKey(32)] + [nonce(24)] + [ciphertext]
  /// This matches Happy Coder's encryptBox implementation.
  Future<Uint8List> encryptBoxBundle(
      Uint8List message, Uint8List recipientPublicKey) async {
    // Use pure Dart crypto_box via pinenacl for compatibility
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

  /// Decrypt Happy Coder's encrypted per-session data key.
  ///
  /// Bundle format:
  /// `[version(1)=0] + [ephemeralPublicKey(32)] + [nonce(24)] + [ciphertext]`
  Future<Uint8List?> decryptHappyCoderDataEncryptionKey(
    String encryptedBase64,
    String secretKey,
  ) async {
    final encryptedBytes = decodeBase64Flexible(encryptedBase64);
    if (encryptedBytes.isEmpty || encryptedBytes.first != 0) {
      return null;
    }

    final masterSecret = decodeBase64Flexible(secretKey);
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
  ///
  /// Payload format:
  /// `[version(1)=0] + [iv(12)] + [ciphertext] + [tag(16)]`
  Future<dynamic> decryptHappyCoderAesGcmJson(
    String encryptedBase64,
    Uint8List secretKey,
  ) async {
    final encryptedBytes = decodeBase64Flexible(encryptedBase64);
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
  ///
  /// Payload format:
  /// `[version(1)=0] + [iv(12)] + [ciphertext] + [tag(16)]`
  Future<String> encryptHappyCoderAesGcmJson(
    Object payload,
    Uint8List secretKey,
  ) async {
    final clearBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(payload)),
    );
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
        1 + nonce.length + secretBox.cipherText.length,
        secretBox.mac.bytes,
      );
    return base64Encode(encoded);
  }

  /// Encrypt Happy Coder legacy secretbox JSON payload.
  ///
  /// Payload format:
  /// `[nonce(24)] + [ciphertext]`
  Future<String> encryptHappyCoderLegacyJson(
    Object payload,
    String secretKey,
  ) async {
    final masterSecret = decodeBase64Flexible(secretKey);
    if (masterSecret.length < 32) {
      throw Exception(
        'Secret key too short: ${masterSecret.length} bytes (expected at least 32 bytes)',
      );
    }

    final normalizedSecret = Uint8List.fromList(masterSecret.sublist(0, 32));
    final box = nacl_secret.SecretBox(normalizedSecret);
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
    final encryptedBytes = decodeBase64Flexible(encryptedBase64);
    if (encryptedBytes.isEmpty) {
      return null;
    }

    final masterSecret = decodeBase64Flexible(secretKey);
    if (masterSecret.length < 32) {
      throw Exception(
        'Secret key too short: ${masterSecret.length} bytes (expected at least 32 bytes)',
      );
    }

    final normalizedSecret = Uint8List.fromList(masterSecret.sublist(0, 32));
    final box = nacl_secret.SecretBox(normalizedSecret);

    try {
      final decrypted = box.decrypt(
        nacl.EncryptedMessage.fromList(encryptedBytes),
      );
      return jsonDecode(utf8.decode(decrypted));
    } catch (e) {
      Logger.warning('Failed to decrypt Happy legacy payload: $e');
      return null;
    }
  }

  /// Derive Happy Coder content public key from account secret.
  ///
  /// Upstream V2 terminal auth does not use the login response's
  /// `encryptionKey` field. It derives a content seed from the master secret
  /// using the `Happy EnCoder -> content` key tree, then converts that seed
  /// into an X25519 public key.
  Future<Uint8List> deriveHappyCoderContentPublicKey(String secretKey) async {
    final masterSecret = decodeBase64Flexible(secretKey);
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

  Uint8List _deriveHappyCoderKey(
    Uint8List masterSecret,
    String usage,
    List<String> path,
  ) {
    var state = _deriveSecretKeyTreeRoot(masterSecret, usage);
    for (final index in path) {
      state = _deriveSecretKeyTreeChild(state.chainCode, index);
    }
    return state.key;
  }

  _KeyTreeState _deriveSecretKeyTreeRoot(Uint8List seed, String usage) {
    final digest = _hmacSha512(
      Uint8List.fromList(utf8.encode('$usage Master Seed')),
      seed,
    );
    return _KeyTreeState(
      key: Uint8List.fromList(digest.sublist(0, 32)),
      chainCode: Uint8List.fromList(digest.sublist(32, 64)),
    );
  }

  _KeyTreeState _deriveSecretKeyTreeChild(Uint8List chainCode, String index) {
    final data = Uint8List.fromList([0x00, ...utf8.encode(index)]);
    final digest = _hmacSha512(chainCode, data);
    return _KeyTreeState(
      key: Uint8List.fromList(digest.sublist(0, 32)),
      chainCode: Uint8List.fromList(digest.sublist(32, 64)),
    );
  }

  Uint8List _hmacSha512(Uint8List key, Uint8List data) {
    final digest = Hmac(sha512, key).convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Generate QR auth key pair for Happy Coder link account
  ///
  /// Returns { publicKey, secretKey, qrData }
  Future<Map<String, dynamic>> generateQRAuthKeyPair() async {
    final keyPair = await generateKeyPair();
    final publicKey = keyPair['publicKey'] as String;

    // QR data format: happy:///account?base64url=<publicKey>
    final publicKeyUrlSafe = base64UrlEncode(publicKey);
    final qrData = 'happy:///account?$publicKeyUrlSafe';

    return {
      'publicKey': publicKey,
      'secretKey': keyPair['secretKey'] as String,
      'qrData': qrData,
    };
  }

  /// Encrypt data specifically for Happy Coder link account approval
  ///
  /// Uses crypto_box to encrypt current user's secret
  Future<String?> cryptoBoxForLink(
      String message, String publicKey, String secretKey) async {
    return cryptoBox(message, publicKey, secretKey);
  }

  /// Decrypt data specifically for Happy Coder link account approval response
  ///
  /// Used to decrypt the encrypted secret returned from server during link auth
  Future<String?> cryptoBoxForLinkApproval(
      String encryptedData, String secretKey) async {
    return cryptoBoxOpenEasy(encryptedData, secretKey);
  }

  /// Base64 URL encode (URL-safe base64 without padding)
  ///
  /// Used for QR code data URL
  static String base64UrlEncode(String input) {
    final bytes = base64Decode(input);
    final base64 = base64Encode(bytes);

    // Remove padding characters
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  /// Base64 URL decode (with padding)
  ///
  /// Adds padding back to make length multiple of 4
  static String base64UrlDecode(String input) {
    var base64 = input;

    // Add padding
    while (base64.length % 4 != 0) {
      base64 += '=';
    }

    // Remove url-safe characters
    base64 = base64.replaceAll('-', '+').replaceAll('_', '/');
    return base64;
  }

  static Uint8List decodeBase64Flexible(String input) {
    var normalized = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return Uint8List.fromList(base64Decode(normalized));
  }
}

class _KeyTreeState {
  const _KeyTreeState({
    required this.key,
    required this.chainCode,
  });

  final Uint8List key;
  final Uint8List chainCode;
}
