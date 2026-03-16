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

import '../../../harmony/harmony_bridge.dart';
import '../../../shared/utils/extensions.dart';

part 'crypto_service_auth.dart';
part 'crypto_service_box.dart';
part 'crypto_service_keypair.dart';
part 'crypto_service_link.dart';
part 'crypto_service_payloads.dart';

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
  static Sodium? _sodiumInstance;

  static Future<CryptoService> get instance async {
    if (_instance != null) {
      return _instance!;
    }
    _instance = CryptoService._();
    return _instance!;
  }

  static Future<Sodium> get _sodium async {
    if (HarmonyBridge.isHarmonyOS) {
      throw Exception('Sodium libs not available on HarmonyOS');
    }
    if (_sodiumInstance == null) {
      _sodiumInstance = await SodiumInit.init();
    }
    return _sodiumInstance!;
  }

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
    for (var index = 0; index < length; index++) {
      buffer[index] = _random.nextInt(256);
    }
    return buffer;
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

  static String base64UrlEncode(String input) {
    final bytes = base64Decode(input);
    final base64 = base64Encode(bytes);
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  static String base64UrlDecode(String input) {
    var base64 = input;
    while (base64.length % 4 != 0) {
      base64 += '=';
    }
    return base64.replaceAll('-', '+').replaceAll('_', '/');
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
