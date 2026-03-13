import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/encryption/domain/crypto_service.dart';

void main() {
  test('decrypts Happy session data encryption key', () async {
    final crypto = await CryptoService.instance;
    final accountSecret = Uint8List.fromList(
      List<int>.generate(32, (index) => index + 1),
    );
    final sessionDataKey = Uint8List.fromList(
      List<int>.generate(32, (index) => 255 - index),
    );

    final contentPublicKey = await crypto.deriveHappyCoderContentPublicKey(
      base64Encode(accountSecret),
    );
    final encryptedBundle = await crypto.encryptBoxBundle(
      sessionDataKey,
      contentPublicKey,
    );
    final wrapped = Uint8List(1 + encryptedBundle.length)
      ..[0] = 0
      ..setAll(1, encryptedBundle);

    final decrypted = await crypto.decryptHappyCoderDataEncryptionKey(
      base64Encode(wrapped),
      base64Encode(accountSecret),
    );

    expect(decrypted, isNotNull);
    expect(decrypted, orderedEquals(sessionDataKey));
  });

  test('decrypts Happy AES-GCM JSON payload', () async {
    final crypto = await CryptoService.instance;
    final sessionDataKey = Uint8List.fromList(
      List<int>.generate(32, (index) => index + 11),
    );
    final nonce = Uint8List.fromList(
      List<int>.generate(12, (index) => index + 21),
    );
    const payload = {
      'path': '/Users/test/project',
      'flavor': 'claude',
      'version': '0.13.0',
    };

    final algorithm = cryptography.AesGcm.with256bits();
    final encrypted = await algorithm.encrypt(
      utf8.encode(jsonEncode(payload)),
      nonce: nonce,
      secretKey: cryptography.SecretKey(sessionDataKey),
    );

    final bundled = Uint8List(
      1 + nonce.length + encrypted.cipherText.length + encrypted.mac.bytes.length,
    )
      ..[0] = 0
      ..setAll(1, nonce)
      ..setAll(1 + nonce.length, encrypted.cipherText)
      ..setAll(
        1 + nonce.length + encrypted.cipherText.length,
        encrypted.mac.bytes,
      );

    final decrypted = await crypto.decryptHappyCoderAesGcmJson(
      base64Encode(bundled),
      sessionDataKey,
    );

    expect(decrypted, isA<Map>());
    expect(decrypted['path'], payload['path']);
    expect(decrypted['flavor'], payload['flavor']);
  });

  test('encrypts Happy AES-GCM payload compatible with decoder', () async {
    final crypto = await CryptoService.instance;
    final sessionDataKey = Uint8List.fromList(
      List<int>.generate(32, (index) => 200 - index),
    );
    const payload = {
      'role': 'user',
      'content': {
        'type': 'text',
        'text': '当前项目目录是哪个',
      },
      'meta': {
        'sentFrom': 'android',
        'permissionMode': 'default',
        'model': null,
      },
    };

    final encrypted = await crypto.encryptHappyCoderAesGcmJson(
      payload,
      sessionDataKey,
    );
    final decrypted = await crypto.decryptHappyCoderAesGcmJson(
      encrypted,
      sessionDataKey,
    );

    expect(decrypted, payload);
  });
}
