part of 'socket_service.dart';

class SocketState {
  const SocketState._();

  static const SocketState initial = SocketState._();

  static SocketState connecting() => const _SocketConnectingState();
  static SocketState connected(String socketId) =>
      _SocketConnectedState(socketId);
  static SocketState reconnecting(int attempt) =>
      _SocketReconnectingState(attempt);
  static SocketState error(String message) => _SocketErrorState(message);

  T when<T>({
    required T Function() initial,
    required T Function() connecting,
    required T Function(String socketId) connected,
    required T Function(int attempt) reconnecting,
    required T Function(String message) error,
  }) {
    if (identical(this, SocketState.initial)) {
      return initial();
    }
    if (this is _SocketConnectingState) {
      return connecting();
    }
    if (this is _SocketConnectedState) {
      return connected((this as _SocketConnectedState).socketId);
    }
    if (this is _SocketReconnectingState) {
      return reconnecting((this as _SocketReconnectingState).attempt);
    }
    if (this is _SocketErrorState) {
      return error((this as _SocketErrorState).message);
    }
    throw UnimplementedError('Unknown SocketState type');
  }

  String? get socketId => this is _SocketConnectedState
      ? (this as _SocketConnectedState).socketId
      : null;

  bool get isConnected => this is _SocketConnectedState;
  bool get isConnecting => this is _SocketConnectingState;
}

class _SocketConnectingState extends SocketState {
  const _SocketConnectingState() : super._();
}

class _SocketConnectedState extends SocketState {
  const _SocketConnectedState(this.socketId) : super._();

  @override
  final String socketId;
}

class _SocketReconnectingState extends SocketState {
  const _SocketReconnectingState(this.attempt) : super._();

  final int attempt;
}

class _SocketErrorState extends SocketState {
  const _SocketErrorState(this.message) : super._();

  final String message;
}
