import 'dart:convert';
import 'dart:typed_data';

import '../../encryption/domain/crypto_service.dart';

Map<String, dynamic>? decodeSessionUpdateMaybeJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, mapValue) => MapEntry(key.toString(), mapValue),
        );
      }
    } catch (_) {}
  }
  return null;
}

Future<Map<String, dynamic>?> decodeSessionUpdateJsonMap({
  required dynamic rawValue,
  required Uint8List? sessionKey,
  required String? secretKey,
  CryptoService? crypto,
}) async {
  if (rawValue == null) {
    return null;
  }
  final maybeJson = decodeSessionUpdateMaybeJsonMap(rawValue);
  if (maybeJson != null) {
    return maybeJson;
  }
  if (rawValue is! String || rawValue.trim().isEmpty) {
    return null;
  }

  final resolvedCrypto = crypto ?? await CryptoService.instance;
  if (sessionKey != null) {
    try {
      final decrypted = await resolvedCrypto.decryptHappyCoderAesGcmJson(
          rawValue, sessionKey);
      final decoded = decodeSessionUpdateMaybeJsonMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    } catch (_) {}
  }

  if (secretKey != null && secretKey.isNotEmpty) {
    try {
      final decrypted =
          await resolvedCrypto.decryptHappyCoderLegacyJson(rawValue, secretKey);
      final decoded = decodeSessionUpdateMaybeJsonMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    } catch (_) {}
  }
  return null;
}
