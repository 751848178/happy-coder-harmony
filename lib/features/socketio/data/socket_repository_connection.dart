part of 'socket_repository.dart';

extension SocketRepositoryConnection on SocketRepository {
  Future<void> initialize({
    required String machineId,
    required String token,
  }) async {
    final tokenChanged = _token != null && _token != token;
    _token = token;

    if (_socket != null) {
      if (_socket!.connected && !tokenChanged) {
        return;
      }
      if (tokenChanged) {
        await disconnect();
      } else {
        _prepareConnectionCompleter();
        _socket!.connect();
        await _awaitConnection();
        return;
      }
    }
    await _connect(waitForReady: true);
  }

  Future<void> ensureConnected({
    required String token,
    Duration timeout = const Duration(milliseconds: AppConfig.connectTimeout),
  }) async {
    final tokenChanged = _token != null && _token != token;
    _token = token;

    if (_socket != null) {
      if (_socket!.connected && !tokenChanged) {
        return;
      }
      if (tokenChanged) {
        await disconnect();
      } else {
        _prepareConnectionCompleter();
        _socket!.connect();
        await _awaitConnection(timeout: timeout);
        return;
      }
    }
    await _connect(waitForReady: true, timeout: timeout);
  }

  Future<void> disconnect() async {
    _deduplicationTimer?.cancel();
    _deduplicationTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _deduplicationSet.clear();
    _lastEphemeralSessionApplyAt.clear();

    _socket?.disconnect();
    _disposeSocketInstance();
    _connectionCompleter = null;
    _reconnectAttempts = 0;

    Logger.info('Socket disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _eventController.close();
    _toolCallRequestController.close();
  }
}
