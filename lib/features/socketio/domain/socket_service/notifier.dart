part of 'socket_service.dart';

class SocketNotifier extends StateNotifier<SocketState> {
  SocketNotifier(this._repository) : super(SocketState.initial);

  final SocketRepository _repository;
  StreamSubscription<SocketEvent>? _eventSubscription;

  Future<void> initialize({
    required String machineId,
    required String token,
  }) async {
    state = SocketState.connecting();

    try {
      _subscribeToEvents();
      await _repository.initialize(
        machineId: machineId,
        token: token,
      );
      Logger.info('Socket initialization started');
    } catch (error) {
      // Don't set error state — the repository's _scheduleReconnect()
      // already handles state via events (reconnecting / error at max).
      Logger.warning(
          'Socket initialize failed (reconnect will continue): $error');
    }
  }

  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    if (_repository.connectionState != SocketConnectionState.connected) {
      Logger.warning('Cannot send message: socket not connected');
      return;
    }

    try {
      await _repository.sendMessage(
        sessionId: sessionId,
        content: content,
        metadata: metadata,
      );
      Logger.info('Message sent to session: $sessionId');
    } catch (error) {
      Logger.error('Failed to send message: $error');
    }
  }

  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    try {
      await _repository.approveToolCall(
        sessionId: sessionId,
        toolId: toolId,
      );
      Logger.info('Tool call approved: $toolId');
    } catch (error) {
      Logger.error('Failed to approve tool call: $error');
      rethrow;
    }
  }

  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    try {
      await _repository.rejectToolCall(
        sessionId: sessionId,
        toolId: toolId,
        reason: reason,
      );
      Logger.info('Tool call rejected: $toolId');
    } catch (error) {
      Logger.error('Failed to reject tool call: $error');
      rethrow;
    }
  }

  void subscribeToSession(String sessionId) {
    _repository.subscribeToSession(sessionId);
    Logger.info('Subscribed to session: $sessionId');
  }

  void unsubscribeFromSession(String sessionId) {
    _repository.unsubscribeFromSession(sessionId);
    Logger.info('Unsubscribed from session: $sessionId');
  }

  Future<void> sendHeartbeat() async {
    try {
      await _repository.sendHeartbeat();
    } catch (error) {
      Logger.error('Heartbeat failed: $error');
    }
  }

  Future<void> disconnect() async {
    try {
      await _unsubscribeFromEvents();
      await _repository.disconnect();
      state = SocketState.initial;
      Logger.info('Socket disconnected');
    } catch (error) {
      Logger.error('Disconnect error: $error');
    }
  }

  Stream<SocketMessage> get messageStream => _repository.messageStream;
  Stream<SocketEvent> get eventStream => _repository.eventStream;
  Stream<ToolCallRequest> get toolCallRequestStream =>
      _repository.toolCallRequestStream;

  void _subscribeToEvents() {
    _unsubscribeFromEvents();
    _eventSubscription = _repository.eventStream.listen((event) {
      event.when(
        connecting: () {
          state = SocketState.connecting();
        },
        connected: (_) {
          state = SocketState.connected(_repository.socketId ?? 'unknown');
        },
        disconnected: (_) {
          state = SocketState.initial;
        },
        error: (message) {
          state = SocketState.error(message);
        },
        messageReceived: (message) {
          Logger.debug('Message received: ${message.id}');
        },
        reconnecting: (attempt) {
          state = SocketState.reconnecting(attempt);
        },
      );
    });
  }

  Future<void> _unsubscribeFromEvents() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribeFromEvents();
    super.dispose();
  }
}
