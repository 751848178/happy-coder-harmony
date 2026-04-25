part of 'socket_repository.dart';

extension SocketRepositoryRpc on SocketRepository {
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    final messageId = StringExtension.generateId();
    _socket!.emit('message', {
      'sid': sessionId,
      'message': content,
      'localId': messageId,
    });
    Logger.debug('Message sent: $messageId');
  }

  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    throw UnimplementedError(
        'Use sessionRpc(permission) instead: $sessionId/$toolId');
  }

  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    throw UnimplementedError(
      'Use sessionRpc(permission) instead: $sessionId/$toolId/$reason',
    );
  }

  Future<Map<String, dynamic>> updateSessionMetadata({
    required String sessionId,
    required String metadata,
    required int expectedVersion,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'update-metadata',
      {
        'sid': sessionId,
        'metadata': metadata,
        'expectedVersion': expectedVersion,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid metadata response'));
          return;
        }
        completer.complete(responseMap);
      },
    );
    return completer.future;
  }

  Future<Map<String, dynamic>> sessionRpc({
    required String sessionId,
    required String method,
    required String encryptedParams,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }
    final completer = Completer<Map<String, dynamic>>();
    _socket!.emitWithAck(
      'rpc-call',
      {
        'method': '$sessionId:$method',
        'params': encryptedParams,
      },
      ack: (dynamic response) {
        final responseMap = _asStringMap(response);
        if (responseMap == null) {
          completer.completeError(Exception('Invalid RPC response'));
          return;
        }
        completer.complete(responseMap);
      },
    );
    final responseMap = await completer.future;
    if (responseMap['ok'] != true) {
      throw Exception(responseMap['error']?.toString() ?? 'RPC call failed');
    }
    return responseMap;
  }

  Future<dynamic> machineRpc({
    required String machineId,
    required String method,
    required Map<String, dynamic> payload,
    Uint8List? dataEncryptionKey,
    String? accountSecret,
  }) =>
      _machineRpc(
        machineId: machineId,
        method: method,
        payload: payload,
        dataEncryptionKey: dataEncryptionKey,
        accountSecret: accountSecret,
      );

  void subscribeToSession(String sessionId) =>
      _subscribeToSocketSession(sessionId);

  void unsubscribeFromSession(String sessionId) =>
      _unsubscribeFromSocketSession(sessionId);

  Future<void> sendHeartbeat() => _sendSocketHeartbeat();

  Future<void> _clearLocalSessionCache(String sessionId) =>
      _clearSocketLocalSessionCache(sessionId);
}
