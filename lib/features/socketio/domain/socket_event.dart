part of 'socket_service.dart';

abstract class SocketEvent {
  static SocketEvent connecting() => _SocketConnectingEvent();
  static SocketEvent connected(String socketId) =>
      _SocketConnectedEvent(socketId);
  static SocketEvent disconnected([String? reason]) =>
      _SocketDisconnectedEvent(reason);
  static SocketEvent error(String message) => _SocketErrorEvent(message);
  static SocketEvent messageReceived(SocketMessage message) =>
      _SocketMessageReceivedEvent(message);
  static SocketEvent reconnecting(int attempt) =>
      _SocketReconnectingEvent(attempt);

  T when<T>({
    T Function()? connecting,
    required T Function(String socketId) connected,
    required T Function(String? reason) disconnected,
    required T Function(String message) error,
    required T Function(SocketMessage message) messageReceived,
    required T Function(int attempt) reconnecting,
  }) {
    if (this is _SocketConnectingEvent) {
      if (connecting != null) {
        return connecting();
      }
    }
    if (this is _SocketConnectedEvent) {
      return connected((this as _SocketConnectedEvent).socketId);
    }
    if (this is _SocketDisconnectedEvent) {
      return disconnected((this as _SocketDisconnectedEvent).reason);
    }
    if (this is _SocketErrorEvent) {
      return error((this as _SocketErrorEvent).message);
    }
    if (this is _SocketMessageReceivedEvent) {
      return messageReceived((this as _SocketMessageReceivedEvent).message);
    }
    if (this is _SocketReconnectingEvent) {
      return reconnecting((this as _SocketReconnectingEvent).attempt);
    }
    throw UnimplementedError('Unknown SocketEvent type');
  }
}

class _SocketConnectingEvent extends SocketEvent {
  _SocketConnectingEvent();
}

class _SocketConnectedEvent extends SocketEvent {
  _SocketConnectedEvent(this.socketId);

  final String socketId;
}

class _SocketDisconnectedEvent extends SocketEvent {
  _SocketDisconnectedEvent([this.reason]);

  final String? reason;
}

class _SocketErrorEvent extends SocketEvent {
  _SocketErrorEvent(this.message);

  final String message;
}

class _SocketMessageReceivedEvent extends SocketEvent {
  _SocketMessageReceivedEvent(this.message);

  final SocketMessage message;
}

class _SocketReconnectingEvent extends SocketEvent {
  _SocketReconnectingEvent(this.attempt);

  final int attempt;
}
