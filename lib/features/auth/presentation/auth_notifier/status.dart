part of 'auth_notifier.dart';

Future<void> _logout(AuthNotifier notifier) async {
  notifier._updateState(AuthState.loading);
  try {
    await notifier._authRepository.logout();
    _stopAccountPolling(notifier);
    notifier._updateState(AuthState.initial);
    Logger.info('User logged out');
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to logout: $e'));
    Logger.error('Logout error: $e');
  }
}

Future<void> _checkAuthStatus(AuthNotifier notifier) async {
  final isAuthenticated = await notifier._authRepository.isAuthenticated();
  if (!isAuthenticated) {
    notifier._updateState(AuthState.initial);
    return;
  }
  final credentials = await notifier._authRepository.getCredentials();
  notifier._updateState(
    credentials != null
        ? AuthState.authenticated(credentials: credentials)
        : AuthState.initial,
  );
}

Future<String?> _pollStatusOnce(AuthNotifier notifier) async {
  try {
    final response = await notifier._authRepository.pollAccountAuthStatus();
    if (response == null) {
      return null;
    }
    if (response.isAuthorized) {
      await _completeAuthorizedAccountAuth(
        notifier,
        response,
        successLog: 'Account auth successful via QR scan',
      );
      return 'authorized';
    }
    if (response.status == AccountAuthStatus.notFound) {
      _stopAccountPolling(notifier);
      Logger.warning('Account auth request not found');
      return 'rejected';
    }
    return null;
  } catch (e) {
    Logger.error('Poll status once error: $e');
    return null;
  }
}
