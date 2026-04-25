import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/models/auth_models.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/utils/extensions.dart';
import '../../../encryption/domain/crypto_service.dart';
import '../../data/auth_repository.dart'
    show
        AccountAuthStatus,
        AccountAuthStatusResponse,
        AuthRepository,
        LoginResponse,
        QRCodeResponse,
        TerminalAuthStatus,
        TerminalAuthStatusResponse;
import '../../data/token_storage_service.dart';

part 'account_auth.dart';
part 'credentials.dart';
part 'link_parsing.dart';
part 'login.dart';
part 'status.dart';
part 'terminal.dart';

/// 认证 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository) : super(AuthState.initial);

  final AuthRepository _authRepository;
  final TokenStorageService _storage = TokenStorageService.instance;

  Timer? _accountPollingTimer;
  DateTime? _qrExpiresAt;

  Credentials? get _currentCredentials => state.credentials;

  void _updateState(AuthState nextState) {
    state = nextState;
  }

  Future<void> loginWithSecretKey(String secretKey) =>
      _loginWithSecretKey(this, secretKey);

  Future<void> loginWithHappySecret(String secret) =>
      _loginWithHappySecret(this, secret);

  Future<void> applyLoginResponse(
    LoginResponse response, {
    required String secret,
  }) =>
      _completeSecretLogin(this, response, secret: secret);

  Future<void> loginWithLink(String linkUrl) => _loginWithLink(this, linkUrl);

  Future<void> generateQRCodeForTerminal() => _generateQRCodeForTerminal(this);

  Future<void> startAccountAuthPolling({
    required String secretKey,
    required DateTime expiresAt,
  }) =>
      _startAccountAuthPolling(
        this,
        secretKey: secretKey,
        expiresAt: expiresAt,
      );

  Future<void> cancelAccountAuth() => _cancelAccountAuth(this);

  Future<bool> connectTerminal(String authUrl) =>
      _connectTerminal(this, authUrl);

  Future<bool> linkAccount(String authUrlOrKey) =>
      _linkAccount(this, authUrlOrKey);

  Future<void> logout() => _logout(this);

  Future<void> checkAuthStatus() => _checkAuthStatus(this);

  Future<String?> pollStatusOnce() => _pollStatusOnce(this);
}
