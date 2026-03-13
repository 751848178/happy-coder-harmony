import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinenacl/api.dart' as nacl;
import 'package:pinenacl/src/authenticated_encryption/public.dart'
    as nacl_public;

import 'package:happy_coder_flutter/features/encryption/domain/crypto_service.dart';

void main() {
  test('terminal V2 response matches upstream Happy Coder protocol', () async {
    final crypto = await CryptoService.instance;

    final accountSecret = Uint8List.fromList(
      List<int>.generate(32, (index) => index + 1),
    );
    final terminalPrivateKey = nacl.PrivateKey.fromSeed(
      Uint8List.fromList(List<int>.generate(32, (index) => index + 33)),
    );

    final contentPublicKey = await crypto.deriveHappyCoderContentPublicKey(
      base64Encode(accountSecret),
    );

    final payload = Uint8List(1 + contentPublicKey.length);
    payload[0] = 0;
    payload.setAll(1, contentPublicKey);

    final encryptedBundle = await crypto.encryptBoxBundle(
      payload,
      Uint8List.fromList(terminalPrivateKey.publicKey),
    );

    final ephemeralPublicKey = encryptedBundle.sublist(0, 32);
    final nonce = encryptedBundle.sublist(32, 56);
    final ciphertext = encryptedBundle.sublist(56);

    final box = nacl_public.Box(
      myPrivateKey: terminalPrivateKey,
      theirPublicKey: nacl.PublicKey(ephemeralPublicKey),
    );
    final decrypted = box.decrypt(nacl.ByteList(ciphertext), nonce: nonce);

    expect(decrypted.first, 0);
    expect(
      decrypted.sublist(1),
      orderedEquals(contentPublicKey),
    );
  });
}
