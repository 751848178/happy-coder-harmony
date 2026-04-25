part of 'socket_repository.dart';

extension SocketRepositoryConnectionSupport on SocketRepository {
  Future<void> _connect({
    bool waitForReady = false,
    Duration timeout = const Duration(milliseconds: AppConfig.connectTimeout),
  }) async {
    try {
      _isConnecting = true;
      _eventController.add(SocketEvent.connecting());
      _prepareConnectionCompleter();
      _disposeSocketInstance();

      final socketUrl = AppConfig.socketUrl;
      Logger.info('Socket connecting to: $socketUrl${AppConfig.socketPath}');
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setPath(AppConfig.socketPath)
            .setTransports(AppConfig.socketTransports)
            .setAuth({'token': _token, 'clientType': 'user-scoped'})
            .disableAutoConnect()
            .disableReconnection()
            .setTimeout(AppConfig.socketTimeout)
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();
      _startDeduplicationTimer();
      if (waitForReady) {
        await _awaitConnection(timeout: timeout);
      }
      Logger.info('Socket connect requested');
    } catch (e) {
      Logger.error('Socket connection error: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      return;
    }

    _socket!
      ..on('connect', (_) {
        Logger.info('Socket connected');
        _isConnecting = false;
        final pendingConnection = _connectionCompleter;
        if (pendingConnection != null && !pendingConnection.isCompleted) {
          pendingConnection.complete();
        }
        _reconnectAttempts = 0;
        _startHeartbeatTimer();
        _eventController.add(SocketEvent.connected(_socket?.id ?? ''));
      })
      ..on('disconnect', (reason) {
        Logger.warning('Socket disconnected: $reason');
        _eventController.add(SocketEvent.disconnected(reason?.toString()));
        _scheduleReconnect();
      })
      ..on('connect_error', (error) {
        Logger.warning('Socket connect error (will retry): $error');
        _scheduleReconnect();
      })
      ..on('message', _handleIncomingMessage)
      ..on('server_message', (data) {
        _handleIncomingMessage(data, type: SocketMessageType.server);
      })
      ..on('tool_call_request', _handleToolCallRequest)
      ..on('update', _handleUpdatePayload)
      ..on('ephemeral', _handleEphemeralPayload)
      ..on('error', (data) {
        Logger.error('Socket error: $data');
        _eventController.add(SocketEvent.error(data.toString()));
      })
      ..on('pong', (_) => Logger.debug('Heartbeat received'));
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= SocketRepository._maxReconnectAttempts) {
      Logger.error('Max reconnection attempts reached');
      _eventController.add(SocketEvent.error('连接失败，请检查网络'));
      return;
    }

    _reconnectAttempts++;
    final delay = AppConfig.socketReconnectDelay * _reconnectAttempts;
    Logger.info(
        'Scheduling reconnect in ${delay}ms (attempt $_reconnectAttempts)');
    _eventController.add(SocketEvent.reconnecting(_reconnectAttempts));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (_socket != null && !_socket!.connected) {
        _connect();
      }
    });
  }

  void _startDeduplicationTimer() {
    _deduplicationTimer?.cancel();
    _deduplicationTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.deduplicationWindow),
      (_) => _deduplicationSet.clear(),
    );
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConfig.sessionHeartbeatInterval),
      (_) => sendHeartbeat(),
    );
  }

  void _disposeSocketInstance() {
    _socket?.clearListeners();
    _socket?.dispose();
    _socket = null;
  }

  void _prepareConnectionCompleter() {
    if (_connectionCompleter == null || _connectionCompleter!.isCompleted) {
      _connectionCompleter = Completer<void>();
    }
  }

  Future<void> _awaitConnection({
    Duration timeout = const Duration(milliseconds: AppConfig.connectTimeout),
  }) async {
    _prepareConnectionCompleter();
    await _connectionCompleter!.future.timeout(
      timeout,
      onTimeout: () => throw Exception('Socket connection timed out'),
    );
  }
}
