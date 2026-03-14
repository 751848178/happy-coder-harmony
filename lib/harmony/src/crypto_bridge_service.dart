import 'channel_invoker.dart';
import 'channel_names.dart';

class CryptoBridgeService extends HarmonyBridgeFeature {
  CryptoBridgeService._() : super(HarmonyChannelNames.libsodium, 'libsodium');

  static final CryptoBridgeService instance = CryptoBridgeService._();

  Future<String?> generateKey() async {
    return invoker.invoke<String>('generateKey');
  }

  Future<Map<String, String>?> generateKeyPair() async {
    final result = await invoker.invoke<Map<dynamic, dynamic>>(
      'generateKeyPair',
      timeout: const Duration(seconds: 10),
    );
    return toStringMap(result);
  }

  Future<String?> encrypt(String data, String key) async {
    return invoker.invoke<String>(
      'encrypt',
      arguments: {
        'data': data,
        'key': key,
      },
    );
  }

  Future<String?> decrypt(String encrypted, String key) async {
    return invoker.invoke<String>(
      'decrypt',
      arguments: {
        'encrypted': encrypted,
        'key': key,
      },
    );
  }

  Future<String?> encryptForPublicKey(String data, String publicKey) async {
    return invoker.invoke<String>(
      'encryptForPublicKey',
      arguments: {
        'data': data,
        'publicKey': publicKey,
      },
    );
  }

  Future<String?> decryptFromPublicKey(
    String encrypted,
    String secretKey,
  ) async {
    return invoker.invoke<String>(
      'decryptFromPublicKey',
      arguments: {
        'encrypted': encrypted,
        'secretKey': secretKey,
      },
    );
  }

  Future<String?> hash(String data) async {
    return invoker.invoke<String>(
      'hash',
      arguments: {'data': data},
    );
  }

  Future<Map<String, String>?> authChallenge(String secretKey) async {
    final result = await invoker.invoke<Map<dynamic, dynamic>>(
      'authChallenge',
      arguments: {'secretKey': secretKey},
    );
    return toStringMap(result);
  }

  Future<String?> getPublicKey(String secretKey) async {
    return invoker.invoke<String>(
      'getPublicKey',
      arguments: {'secretKey': secretKey},
    );
  }
}
