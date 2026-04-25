part of 'socket_repository.dart';

extension SocketRepositoryMachineRpc on SocketRepository {
  Future<dynamic> _machineRpc({
    required String machineId,
    required String method,
    required Map<String, dynamic> payload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    final encryptedParams = await _encryptMachineRpcPayload(
      payload: payload,
      dataEncryptionKey: dataEncryptionKey,
      accountSecret: accountSecret,
    );
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'rpc-call',
      {
        'method': '$machineId:$method',
        'params': encryptedParams,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid machine RPC response'));
          return;
        }
        completer.complete(responseMap);
      },
    );
    final responseMap = await completer.future;
    if (responseMap['ok'] != true) {
      throw Exception(
          responseMap['error']?.toString() ?? 'Machine RPC call failed');
    }
    final encryptedResult = responseMap['result'];
    if (encryptedResult is! String || encryptedResult.isEmpty) {
      return encryptedResult;
    }
    return _decryptMachineRpcPayload(
      encryptedPayload: encryptedResult,
      dataEncryptionKey: dataEncryptionKey,
      accountSecret: accountSecret,
    );
  }

  Future<String> _encryptMachineRpcPayload({
    required Map<String, dynamic> payload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    final crypto = await CryptoService.instance;
    if (dataEncryptionKey != null) {
      return crypto.encryptHappyCoderAesGcmJson(payload, dataEncryptionKey);
    }
    if (accountSecret != null && accountSecret.isNotEmpty) {
      return crypto.encryptHappyCoderLegacyJson(payload, accountSecret);
    }
    final machineKey = await _tokenStorage.getMachineKey();
    if (machineKey == null || machineKey.isEmpty) {
      throw Exception('Missing machine encryption key');
    }
    final encrypted =
        await HarmonyBridge.encrypt(jsonEncode(payload), machineKey);
    if (encrypted == null || encrypted.isEmpty) {
      throw Exception('Failed to encrypt machine RPC payload');
    }
    return encrypted;
  }

  Future<dynamic> _decryptMachineRpcPayload({
    required String encryptedPayload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) async {
    final crypto = await CryptoService.instance;
    if (dataEncryptionKey != null) {
      final decrypted = await crypto.decryptHappyCoderAesGcmJson(
          encryptedPayload, dataEncryptionKey);
      if (decrypted != null) {
        return decrypted;
      }
    }
    if (accountSecret != null && accountSecret.isNotEmpty) {
      final decrypted = await crypto.decryptHappyCoderLegacyJson(
          encryptedPayload, accountSecret);
      if (decrypted != null) {
        return decrypted;
      }
    }
    final machineKey = await _tokenStorage.getMachineKey();
    if (machineKey == null || machineKey.isEmpty) {
      throw Exception('Missing machine encryption key');
    }
    final decrypted = await HarmonyBridge.decrypt(encryptedPayload, machineKey);
    if (decrypted == null || decrypted.isEmpty) {
      throw Exception('Failed to decrypt machine RPC response');
    }
    try {
      return jsonDecode(decrypted);
    } catch (_) {
      return decrypted;
    }
  }
}
