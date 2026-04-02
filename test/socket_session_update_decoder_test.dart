import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:happy_coder_flutter/features/encryption/domain/crypto_service.dart';
import 'package:happy_coder_flutter/features/socketio/data/socket_session_update_decoder.dart';

void main() {
  test('decodes AES-GCM encrypted session update payload', () async {
    final crypto = await CryptoService.instance;
    final sessionKey = Uint8List.fromList(
      List<int>.generate(32, (index) => 64 - index),
    );
    const payload = <String, dynamic>{
      'currentModelCode': 'gpt-5-codex-high',
      'models': [
        {'code': 'gpt-5-codex-high', 'value': 'GPT-5 Codex High'},
      ],
    };

    final encrypted = await crypto.encryptHappyCoderAesGcmJson(
      payload,
      sessionKey,
    );

    final decoded = await decodeSessionUpdateJsonMap(
      rawValue: encrypted,
      sessionKey: sessionKey,
      secretKey: null,
      crypto: crypto,
    );

    expect(decoded, payload);
  });

  test('decodes legacy encrypted session update payload', () async {
    final crypto = await CryptoService.instance;
    final secretKey = base64Encode(
      Uint8List.fromList(List<int>.generate(32, (index) => index + 7)),
    );
    const payload = <String, dynamic>{
      'currentOperatingModeCode': 'plan',
    };

    final encrypted = await crypto.encryptHappyCoderLegacyJson(
      payload,
      secretKey,
    );

    final decoded = await decodeSessionUpdateJsonMap(
      rawValue: encrypted,
      sessionKey: null,
      secretKey: secretKey,
      crypto: crypto,
    );

    expect(decoded, payload);
  });
}
