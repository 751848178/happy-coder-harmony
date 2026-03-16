part of 'auth_notifier.dart';

Future<void> _loginWithSecretKey(
    AuthNotifier notifier, String secretKey) async {
  await _performSecretLogin(
    notifier,
    secret: secretKey,
    login: notifier._authRepository.loginWithSecretKey,
    successLog: 'Login with secret key successful',
    errorPrefix: 'Login with secret key',
  );
}

Future<void> _loginWithHappySecret(AuthNotifier notifier, String secret) async {
  await _performSecretLogin(
    notifier,
    secret: secret,
    login: notifier._authRepository.loginWithSecret,
    successLog: 'Login with Happy Coder secret successful',
    errorPrefix: 'Login with Happy Coder secret',
  );
}

Future<void> _loginWithLink(AuthNotifier notifier, String linkUrl) async {
  notifier._updateState(AuthState.loading);
  try {
    if (linkUrl.startsWith('happy:///account?')) {
      await _startAccountAuth(notifier, linkUrl);
      return;
    }
    final secretKey = _parseLinkForSecretKey(notifier, linkUrl);
    if (secretKey == null) {
      throw Exception('Invalid link format');
    }
    final response =
        await notifier._authRepository.loginWithSecretKey(secretKey);
    await _completeSecretLogin(notifier, response, secret: secretKey);
    Logger.info('Login with link successful: $linkUrl');
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to login: $e'));
    Logger.error('Login with link error: $e');
  }
}

Future<void> _performSecretLogin(
  AuthNotifier notifier, {
  required String secret,
  required Future<LoginResponse> Function(String secret) login,
  required String successLog,
  required String errorPrefix,
}) async {
  notifier._updateState(AuthState.loading);
  try {
    final response = await login(secret);
    await _completeSecretLogin(notifier, response, secret: secret);
    Logger.info(successLog);
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to login: $e'));
    Logger.error('$errorPrefix error: $e');
  }
}
