import 'dart:convert';
import 'dart:async';

import '../../socketio/data/socket_repository.dart';
import '../../socketio/domain/socket_service.dart';
import '../../../shared/utils/extensions.dart';
import '../domain/reducer.dart';
import '../domain/session_service.dart';

part 'socket_integration_message_parsing.dart';
part 'socket_integration_message_builders.dart';

class SocketIntegration {
  SocketIntegration._();

  static final SocketIntegration instance = SocketIntegration._();

  final SocketRepository _socketRepository = SocketRepository.instance;
  SessionServiceNotifier? _sessionService;
  StreamSubscription<SocketEvent>? _eventSubscription;
  StreamSubscription<SocketMessage>? _messageSubscription;
  String? _currentSessionId;

  void setSessionService(SessionServiceNotifier sessionService) {
    _sessionService = sessionService;
  }

  void initialize() {
    _subscribeToEvents();
    Logger.info('Socket-Session integration initialized');
  }

  void _subscribeToEvents() {
    _eventSubscription = _socketRepository.eventStream.listen((event) {
      event.when(
        connecting: () => Logger.info('Socket connecting...'),
        connected: (_) => _handleConnected(),
        disconnected: _handleDisconnected,
        error: (message) => Logger.error('Socket error: $message'),
        messageReceived: _handleMessageReceived,
        reconnecting: (attempt) =>
            Logger.info('Socket reconnecting: attempt $attempt'),
      );
    });
    _messageSubscription = _socketRepository.messageStream.listen(
      _handleMessageReceived,
    );
  }

  void _handleConnected() {
    Logger.info('Socket connected, subscribing to sessions');
    if (_currentSessionId != null) {
      _socketRepository.subscribeToSession(_currentSessionId!);
    }
  }

  void _handleDisconnected(String? reason) {
    Logger.warning('Socket disconnected: $reason');
  }

  void _handleMessageReceived(SocketMessage socketMessage) {
    final reducerMessage = _convertToReducerMessage(socketMessage);
    if (reducerMessage != null && socketMessage.sessionId != null) {
      _sessionService?.loadSessionMessages(
        socketMessage.sessionId!,
        messageWindowSize:
            SessionServiceNotifier.sessionDetailAutomaticMessageWindowSize,
      );
    }
  }

  void setCurrentSession(String sessionId) {
    _currentSessionId = sessionId;
    _socketRepository.subscribeToSession(sessionId);
    Logger.info('Current session set to: $sessionId');
  }

  void clearCurrentSession() {
    if (_currentSessionId != null) {
      _socketRepository.unsubscribeFromSession(_currentSessionId!);
      _currentSessionId = null;
    }
    Logger.info('Current session cleared');
  }

  Future<void> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return _socketRepository.sendMessage(
      sessionId: sessionId,
      content: content,
      metadata: metadata,
    );
  }

  Future<void> approveToolCall({
    required String sessionId,
    required String toolId,
  }) async {
    final service = _sessionService;
    if (service == null) {
      throw UnsupportedError('SessionService is not initialized');
    }
    await service.submitToolApproval(sessionId: sessionId, toolId: toolId);
  }

  Future<void> rejectToolCall({
    required String sessionId,
    required String toolId,
    String? reason,
  }) async {
    final service = _sessionService;
    if (service == null) {
      throw UnsupportedError('SessionService is not initialized');
    }
    await service.submitToolRejection(
      sessionId: sessionId,
      toolId: toolId,
      reason: reason,
    );
  }

  void dispose() {
    _eventSubscription?.cancel();
    _messageSubscription?.cancel();
    Logger.info('Socket-Session integration disposed');
  }
}
