part of 'qr_code_screen.dart';

Future<void> _generateQRCodeImpl(
  _QRCodeScreenState state, {
  bool isRefresh = false,
}) async {
  if (state._isRefreshing) {
    return;
  }

  state._updateView(() {
    if (isRefresh) {
      state._isRefreshing = true;
    } else {
      state._isLoading = true;
    }
    state._errorMessage = null;
    state._qrData = null;
    state._isPolling = false;
    state._pollingStatus = null;
  });

  try {
    final crypto = await CryptoService.instance;
    final keyPairResult = await crypto.generateQRAuthKeyPair();
    final publicKey = keyPairResult['publicKey'] as String;
    final secretKey = keyPairResult['secretKey'] as String;
    final qrData = keyPairResult['qrData'] as String;
    Logger.info('Generated QR auth key pair, public key: $publicKey');

    await PlatformStorage.instance.write(
      key: 'temp_secret_key',
      value: secretKey,
    );

    state._updateView(() {
      state._qrData = qrData;
      state._qrId = publicKey.substring(0, 16);
      state._expiresAt = DateTime.now().add(const Duration(minutes: 5));
      state._isLoading = false;
      state._isRefreshing = false;
    });

    state._startCountdown(state._expiresAt!);
    state._startStatusPolling();
  } catch (e) {
    state._updateView(() {
      state._errorMessage = '生成 QR 码失败: $e';
      state._isLoading = false;
      state._isRefreshing = false;
    });
    Logger.error('Generate QR code error: $e');
  }
}

void _startCountdownImpl(_QRCodeScreenState state, DateTime expiresAt) {
  state._countdownTimer?.cancel();
  state._countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) {
      timer.cancel();
      state._generateQRCode(isRefresh: true);
      return;
    }
    if (!state.mounted) {
      return;
    }
    state._updateView(() {
      state._secondsRemaining = seconds;
    });
  });
}

void _startStatusPollingImpl(_QRCodeScreenState state) {
  state._statusPollingTimer?.cancel();
  state._statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (
    timer,
  ) async {
    if (state._isPolling || state._isManualConfirm) {
      return;
    }

    state._updateView(() {
      state._isPolling = true;
    });

    try {
      final authNotifier = state.ref.read(authStateProvider.notifier);
      final status = await authNotifier.pollStatusOnce();
      if (status == null) {
        return;
      }
      timer.cancel();
      state._countdownTimer?.cancel();
      if (!state.mounted) {
        return;
      }
      state._updateView(() {
        state._pollingStatus = status;
      });
    } catch (e) {
      Logger.error('Poll status error: $e');
    } finally {
      if (state.mounted) {
        state._updateView(() {
          state._isPolling = false;
        });
      }
    }
  });
  Logger.info('Status polling started');
}

void _toggleManualConfirmImpl(_QRCodeScreenState state) {
  state._updateView(() {
    state._isManualConfirm = !state._isManualConfirm;
  });
  state._confirmCodeController.clear();
}

Future<void> _refreshQRCodeImpl(_QRCodeScreenState state) async {
  await state._generateQRCode(isRefresh: true);
}

void _cancelQRCodeScreen(_QRCodeScreenState state) {
  state._countdownTimer?.cancel();
  state._statusPollingTimer?.cancel();
  state.context.pop();
}

String _formatDurationValue(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
