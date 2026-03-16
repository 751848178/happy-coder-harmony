part of 'livekit_service.dart';

sealed class LiveKitConnectionState {
  const LiveKitConnectionState();

  String? get errorMessage {
    if (this is ErrorState) {
      return (this as ErrorState).message;
    }
    return null;
  }
}

class InitialState extends LiveKitConnectionState {
  const InitialState();
}

class ConnectingState extends LiveKitConnectionState {
  const ConnectingState();
}

class ConnectedState extends LiveKitConnectionState {
  const ConnectedState();
}

class DisconnectingState extends LiveKitConnectionState {
  const DisconnectingState();
}

class DisconnectedState extends LiveKitConnectionState {
  const DisconnectedState();
}

class ErrorState extends LiveKitConnectionState {
  const ErrorState(this.message);

  final String message;
}

class LiveKitConnectionStates {
  static const LiveKitConnectionState initial = InitialState();
  static const LiveKitConnectionState connecting = ConnectingState();
  static const LiveKitConnectionState connected = ConnectedState();
  static const LiveKitConnectionState disconnecting = DisconnectingState();
  static const LiveKitConnectionState disconnected = DisconnectedState();

  static LiveKitConnectionState error(String message) => ErrorState(message);
}
