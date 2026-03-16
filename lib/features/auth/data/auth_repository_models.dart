part of 'auth_repository.dart';

class AccountAuthStatusResponse {
  const AccountAuthStatusResponse({
    required this.status,
    this.supportsV2 = false,
    this.token,
    this.machineId,
    this.encryptionKey,
    this.encryptionType,
    this.publicKey,
  });

  final AccountAuthStatus status;
  final bool supportsV2;
  final String? token;
  final String? machineId;
  final String? encryptionKey;
  final String? encryptionType;
  final String? publicKey;

  bool get isAuthorized =>
      status == AccountAuthStatus.authorized && token != null;
}

enum AccountAuthStatus {
  notFound,
  pending,
  authorized,
}

AccountAuthStatus accountAuthStatusFromState(String? state) {
  switch (state) {
    case 'pending':
      return AccountAuthStatus.pending;
    case 'authorized':
      return AccountAuthStatus.authorized;
    case 'not_found':
    default:
      return AccountAuthStatus.notFound;
  }
}

class QRCodeResponse {
  const QRCodeResponse({
    required this.qrId,
    required this.qrData,
    required this.expiresAt,
    this.secretKey,
  });

  final String qrId;
  final String qrData;
  final DateTime expiresAt;
  final String? secretKey;
}

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.machineId,
    this.encryptionKey,
    required this.encryptionType,
    this.publicKey,
    this.machineKey,
    this.secret,
  });

  final String token;
  final String machineId;
  final String? encryptionKey;
  final EncryptionType encryptionType;
  final String? publicKey;
  final String? machineKey;
  final String? secret;
}

class TerminalAuthStatusResponse {
  const TerminalAuthStatusResponse({
    required this.status,
    required this.supportsV2,
  });

  final TerminalAuthStatus status;
  final bool supportsV2;
}

enum TerminalAuthStatus {
  notFound,
  pending,
  authorized,
}

TerminalAuthStatus terminalAuthStatusFromState(String? state) {
  switch (state) {
    case 'pending':
      return TerminalAuthStatus.pending;
    case 'authorized':
      return TerminalAuthStatus.authorized;
    case 'not_found':
    default:
      return TerminalAuthStatus.notFound;
  }
}
