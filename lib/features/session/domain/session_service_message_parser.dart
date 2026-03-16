part of 'session_service.dart';

extension SessionServiceMessageParser on SessionServiceNotifier {
  Future<Map<String, dynamic>?> _decodeEncryptedJsonMap(
    dynamic rawValue, {
    Uint8List? dataKey,
    String? secretKey,
  }) async {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is Map<String, dynamic>) {
      return rawValue;
    }
    if (rawValue is Map) {
      return _asStringMap(rawValue);
    }
    if (rawValue is! String || rawValue.trim().isEmpty) {
      return null;
    }

    final maybeJson = _decodeMaybeJsonMap(rawValue);
    if (maybeJson != null) {
      return maybeJson;
    }
    if (!_looksLikeBase64(rawValue)) {
      return null;
    }

    final crypto = await CryptoService.instance;
    if (dataKey != null) {
      final decrypted =
          await crypto.decryptHappyCoderAesGcmJson(rawValue, dataKey);
      final decoded = _asStringMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    }

    if (secretKey != null && secretKey.isNotEmpty) {
      final decrypted =
          await crypto.decryptHappyCoderLegacyJson(rawValue, secretKey);
      final decoded = _asStringMap(decrypted);
      if (decoded != null) {
        return decoded;
      }
    }
    return null;
  }

  Future<List<ReducerMessage>> _parseServerMessages(
    Map<String, dynamic> messageJson, {
    Uint8List? sessionKey,
    String? secretKey,
  }) async {
    final createdAt = messageJson['createdAt'] != null
        ? _parseMessageDateTime(messageJson['createdAt']) ?? DateTime.now()
        : DateTime.now();
    final messageId = messageJson['id'] as String? ?? '';
    final localId = messageJson['localId']?.toString();
    final content = _asStringMap(messageJson['content']);
    final payload = content?['c'];
    final contentType = content?['t']?.toString();

    if (payload is String && payload.isNotEmpty) {
      final rawRecord = await _decodeEncryptedJsonMap(
        payload,
        dataKey: sessionKey,
        secretKey: secretKey,
      );
      if (rawRecord != null) {
        final reduced = _reduceRawRecordMessages(
          rawRecord,
          id: messageId,
          createdAt: createdAt,
          localId: localId,
        );
        if (reduced.isNotEmpty) {
          return reduced;
        }
      }

      if (contentType == 'encrypted' && _looksLikeBase64(payload)) {
        return const <ReducerMessage>[];
      }
      return <ReducerMessage>[
        ReducerMessage(
          id: messageId,
          kind: 'text',
          createdAt: createdAt,
          text: payload,
          metadata: {
            ...?_asStringMap(messageJson['metadata']),
            if (localId != null && localId.isNotEmpty) 'localId': localId,
          },
        ),
      ];
    }

    return <ReducerMessage>[ReducerMessage.fromJson(messageJson)];
  }

  List<ReducerMessage> _reduceRawRecordMessages(
    Map<String, dynamic> rawRecord, {
    required String id,
    required DateTime createdAt,
    String? localId,
  }) {
    final role = rawRecord['role']?.toString();
    final meta = _asStringMap(rawRecord['meta']);
    final content = _asStringMap(rawRecord['content']);

    switch (role) {
      case 'user':
        final text = content?['text']?.toString();
        if (text == null || text.isEmpty) {
          return const <ReducerMessage>[];
        }
        return <ReducerMessage>[
          _buildTextReducerMessage(
            id: id,
            createdAt: createdAt,
            text: text,
            metadata: {
              ...?meta,
              'role': 'user',
              if (localId != null && localId.isNotEmpty) 'localId': localId,
            },
          ),
        ];
      case 'session':
        return _reduceSessionEnvelopeMessages(
          envelope: _asStringMap(content?['data']),
          id: id,
          createdAt: createdAt,
          localId: localId,
          meta: meta,
        );
      case 'agent':
        final contentType = content?['type']?.toString();
        if (contentType == 'codex') {
          return _reduceCodexMessages(
            codexData: _asStringMap(content?['data']),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }
        if (contentType == 'acp') {
          return _reduceAcpMessages(
            acpData: _asStringMap(content?['data']),
            provider: content?['provider']?.toString(),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }
        if (contentType == 'output') {
          return _reduceOutputMessages(
            outputData: _asStringMap(content?['data']),
            id: id,
            createdAt: createdAt,
            localId: localId,
            meta: meta,
          );
        }
        return const <ReducerMessage>[];
      default:
        return const <ReducerMessage>[];
    }
  }
}
