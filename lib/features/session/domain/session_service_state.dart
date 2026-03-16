part of 'session_service.dart';

class SessionServiceState {
  const SessionServiceState._();

  static const SessionServiceState initial = _SessionServiceInitialState();

  static const SessionServiceState loading = _SessionServiceLoadingState();

  static SessionServiceState ready({
    required Map<String, Session> sessions,
    required Map<String, SessionMessages> sessionMessages,
    required Map<String, Machine> machines,
  }) =>
      _SessionServiceReadyState(
        sessions: sessions,
        sessionMessages: sessionMessages,
        machines: machines,
      );

  static SessionServiceState error(String message) =>
      _SessionServiceErrorState(message);

  T whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(
            Map<String, Session> sessions,
            Map<String, SessionMessages> sessionMessages,
            Map<String, Machine> machines)?
        ready,
    T Function(String message)? error,
  }) {
    if (this is _SessionServiceReadyState && ready != null) {
      final state = this as _SessionServiceReadyState;
      return ready(state.sessions, state.sessionMessages, state.machines);
    }
    if (this is _SessionServiceLoadingState && loading != null) {
      return loading();
    }
    if (this is _SessionServiceErrorState && error != null) {
      return error((this as _SessionServiceErrorState).message);
    }
    if (initial != null) {
      return initial();
    }
    return null as T;
  }

  T when<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(
            Map<String, Session> sessions,
            Map<String, SessionMessages> sessionMessages,
            Map<String, Machine> machines)?
        ready,
    T Function(String message)? error,
  }) {
    return whenOrNull(
      initial: initial ?? () => throw Exception('Unhandled initial state'),
      loading: loading ?? () => throw Exception('Unhandled loading state'),
      ready: ready ??
          (sessions, sessionMessages, machines) =>
              throw Exception('Unhandled ready state'),
      error: error ?? (message) => throw Exception('Unhandled error state'),
    )!;
  }
}

class _SessionServiceInitialState extends SessionServiceState {
  const _SessionServiceInitialState() : super._();
}

class _SessionServiceLoadingState extends SessionServiceState {
  const _SessionServiceLoadingState() : super._();
}

class _SessionServiceReadyState extends SessionServiceState {
  const _SessionServiceReadyState({
    required this.sessions,
    required this.sessionMessages,
    required this.machines,
  }) : super._();

  final Map<String, Session> sessions;
  final Map<String, SessionMessages> sessionMessages;
  final Map<String, Machine> machines;
}

class _SessionServiceErrorState extends SessionServiceState {
  const _SessionServiceErrorState(this.message) : super._();

  final String message;
}

class SessionSpawnResult {
  const SessionSpawnResult._({
    this.sessionId,
    this.directoryApprovalPath,
    this.errorMessage,
  });

  const SessionSpawnResult.success(String sessionId)
      : this._(sessionId: sessionId);

  const SessionSpawnResult.directoryApproval(String directory)
      : this._(directoryApprovalPath: directory);

  const SessionSpawnResult.error(String message)
      : this._(errorMessage: message);

  final String? sessionId;
  final String? directoryApprovalPath;
  final String? errorMessage;

  bool get isSuccess => sessionId != null && sessionId!.isNotEmpty;

  bool get requiresDirectoryApproval =>
      directoryApprovalPath != null && directoryApprovalPath!.isNotEmpty;
}
