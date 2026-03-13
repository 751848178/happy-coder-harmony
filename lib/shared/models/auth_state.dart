import 'auth_models.dart';

/// 认证状态
class AuthState {
  const AuthState._();

  static const AuthState initial = _InitialState();
  static const AuthState loading = _LoadingState();
  static AuthState authenticated({required Credentials credentials}) =>
      _AuthenticatedState(credentials);
  static AuthState qrCode({
    required String qrId,
    required String qrData,
    required DateTime expiresAt,
  }) => _QrCodeState(qrId, qrData, expiresAt);
  static AuthState backupSuccess({
    required String backupId,
    required String encryptedData,
  }) => _BackupSuccessState(backupId, encryptedData);
  static AuthState error(String message) => _ErrorState(message);

  /// 账户认证轮询状态（Happy Coder 格式）
  static AuthState accountAuthPolling({
    required String publicKey,
    required DateTime expiresAt,
  }) => _AccountAuthPollingState(publicKey: publicKey, expiresAt: expiresAt);
  static AuthState accountAuthAuthorized({required String token}) =>
      _AccountAuthAuthorizedState(token: token);
  static AuthState accountAuthError(String message) => _AccountAuthErrorState(message: message);
  static AuthState accountAuthNotFound() => _AccountAuthNotFoundState();
  static AuthState accountAuthCancelled() => _AccountAuthCancelledState();

  Credentials? get credentials => this is _AuthenticatedState
      ? (this as _AuthenticatedState).credentials
      : null;
  bool get isLoading => this is _LoadingState;
  bool get isAuthenticated => this is _AuthenticatedState;
  bool get isError => this is _ErrorState;
  String? get errorMessage => this is _ErrorState ? (this as _ErrorState).message : null;
  String? get qrId => this is _QrCodeState ? (this as _QrCodeState).qrId : null;
  String? get qrData => this is _QrCodeState ? (this as _QrCodeState).qrData : null;
  DateTime? get qrExpiresAt => this is _QrCodeState ? (this as _QrCodeState).expiresAt : null;
  String? get backupId => this is _BackupSuccessState ? (this as _BackupSuccessState).backupId : null;
  String? get encryptedData => this is _BackupSuccessState ? (this as _BackupSuccessState).encryptedData : null;

  T? maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(Credentials credentials)? authenticated,
    T Function(String qrId, String qrData, DateTime expiresAt)? qrCode,
    T Function(String backupId, String encryptedData)? backupSuccess,
    T Function(String message)? error,
  }) {
    if (this is _InitialState && initial != null) {
      return initial();
    }
    if (this is _LoadingState && loading != null) {
      return loading();
    }
    if (this is _AuthenticatedState && authenticated != null) {
      return authenticated((this as _AuthenticatedState).credentials);
    }
    if (this is _QrCodeState && qrCode != null) {
      final state = this as _QrCodeState;
      return qrCode(state.qrId, state.qrData, state.expiresAt);
    }
    if (this is _BackupSuccessState && backupSuccess != null) {
      final state = this as _BackupSuccessState;
      return backupSuccess(state.backupId, state.encryptedData);
    }
    if (this is _ErrorState && error != null) {
      return error((this as _ErrorState).message);
    }
    return null;
  }

  /// 获取账户认证轮询状态数据
  String? get accountAuthPublicKey {
    if (this is _AccountAuthPollingState) {
      return (this as _AccountAuthPollingState).publicKey;
    }
    return null;
  }

  DateTime? get accountAuthExpiresAt {
    if (this is _AccountAuthPollingState) {
      return (this as _AccountAuthPollingState).expiresAt;
    }
    return null;
  }
}

class _InitialState extends AuthState {
  const _InitialState() : super._();
}

class _LoadingState extends AuthState {
  const _LoadingState() : super._();
}

class _AuthenticatedState extends AuthState {
  @override
  final Credentials credentials;

  const _AuthenticatedState(this.credentials) : super._();
}

class _QrCodeState extends AuthState {
  final String qrId;
  final String qrData;
  final DateTime expiresAt;

  const _QrCodeState(this.qrId, this.qrData, this.expiresAt)
      : super._();
}

class _BackupSuccessState extends AuthState {
  final String backupId;
  final String encryptedData;

  const _BackupSuccessState(this.backupId, this.encryptedData)
      : super._();
}

class _ErrorState extends AuthState {
  final String message;

  const _ErrorState(this.message) : super._();
}

/// 账户认证轮询状态（Happy Coder 格式）
class _AccountAuthPollingState extends AuthState {
  final String publicKey;
  final DateTime expiresAt;

  const _AccountAuthPollingState({required this.publicKey, required this.expiresAt})
      : super._();
}

class _AccountAuthAuthorizedState extends AuthState {
  final String token;

  const _AccountAuthAuthorizedState({required this.token}) : super._();
}

class _AccountAuthErrorState extends AuthState {
  final String message;

  const _AccountAuthErrorState({required this.message}) : super._();
}

class _AccountAuthNotFoundState extends AuthState {
  const _AccountAuthNotFoundState() : super._();
}

class _AccountAuthCancelledState extends AuthState {
  const _AccountAuthCancelledState() : super._();
}
