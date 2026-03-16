part of 'auth_notifier.dart';

Future<void> _startAccountAuth(AuthNotifier notifier, String linkUrl) async {
  try {
    final uri = Uri.parse(linkUrl);
    final base64url = uri.queryParameters['base64url'];
    if (base64url == null) {
      throw Exception('Missing base64url parameter');
    }
    final publicKey = _toStandardBase64(base64url);
    Logger.info('Public key from link: $publicKey');
    await notifier._storage.write(key: 'temp_public_key', value: publicKey);
    _beginAccountAuthPolling(
      notifier,
      publicKey: publicKey,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    Logger.info('Account auth polling started');
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to start account auth: $e'));
    Logger.error('Start account auth error: $e');
  }
}

Future<void> _generateQRCodeForTerminal(AuthNotifier notifier) async {
  notifier._updateState(AuthState.loading);
  try {
    final QRCodeResponse response =
        await notifier._authRepository.generateQRCodeForTerminal();
    notifier._qrExpiresAt = response.expiresAt;
    notifier._updateState(AuthState.qrCode(
      qrId: response.qrId,
      qrData: response.qrData,
      expiresAt: response.expiresAt,
    ));
    Logger.info('QR code generated: ${response.qrId}');
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to generate QR code: $e'));
    _stopAccountPolling(notifier);
    Logger.error('Generate QR code error: $e');
  }
}

Future<void> _startAccountAuthPolling(
  AuthNotifier notifier, {
  required String secretKey,
  required DateTime expiresAt,
}) async {
  try {
    final crypto = await CryptoService.instance;
    final publicKey = await crypto.getPublicKey(secretKey);
    _beginAccountAuthPolling(
      notifier,
      publicKey: publicKey,
      expiresAt: expiresAt,
    );
    Logger.info('Account auth polling started for create account');
  } catch (e) {
    Logger.error('Start account auth polling failed: $e');
    notifier._updateState(AuthState.error('Failed to start account auth: $e'));
  }
}

Future<void> _cancelAccountAuth(AuthNotifier notifier) async {
  notifier._updateState(AuthState.loading);
  try {
    _stopAccountPolling(notifier);
    await notifier._storage.delete('temp_secret');
    notifier._updateState(AuthState.initial);
    Logger.info('Account auth cancelled');
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to cancel: $e'));
    Logger.error('Cancel account auth error: $e');
  }
}

void _beginAccountAuthPolling(
  AuthNotifier notifier, {
  required String publicKey,
  required DateTime expiresAt,
}) {
  notifier._qrExpiresAt = expiresAt;
  _startAccountPolling(notifier, publicKey);
  notifier._updateState(AuthState.accountAuthPolling(
    publicKey: publicKey,
    expiresAt: expiresAt,
  ));
}

void _startAccountPolling(AuthNotifier notifier, String publicKey) {
  _stopAccountPolling(notifier);
  notifier._accountPollingTimer = Timer.periodic(
    const Duration(seconds: 2),
    (_) => _pollAccountAuth(notifier, publicKey),
  );
}

void _stopAccountPolling(AuthNotifier notifier) {
  notifier._accountPollingTimer?.cancel();
  notifier._accountPollingTimer = null;
  if (notifier._qrExpiresAt != null) {
    final duration = DateTime.now().difference(notifier._qrExpiresAt!);
    Logger.info('Account auth polling stopped after ${duration.inSeconds}s');
  }
  notifier._storage.delete('temp_public_key');
}

Future<void> _pollAccountAuth(AuthNotifier notifier, String publicKey) async {
  try {
    if (notifier._qrExpiresAt != null &&
        DateTime.now().isAfter(notifier._qrExpiresAt!)) {
      _stopAccountPolling(notifier);
      notifier._updateState(AuthState.error('Account auth request expired'));
      return;
    }
    final response = await notifier._authRepository.pollAccountAuthStatus();
    if (response == null) {
      return;
    }
    if (response.isAuthorized) {
      await _completeAuthorizedAccountAuth(
        notifier,
        response,
        successLog: 'Account auth successful: linked device authorized',
      );
      return;
    }
    if (response.status == AccountAuthStatus.notFound) {
      _stopAccountPolling(notifier);
      notifier._updateState(AuthState.error('Account auth request not found'));
    }
  } catch (e) {
    Logger.error('Poll account auth error: $e');
  }
}
