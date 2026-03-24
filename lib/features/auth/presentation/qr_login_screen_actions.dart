part of 'qr_login_screen.dart';

Future<void> _startQrScanLogin(_QRLoginScreenState state) async {
  if (state._isScanning) {
    return;
  }
  state._updateView(() => state._isScanning = true);
  final link = await showQrScanner(
    state.context,
    title: '扫描登录二维码',
    description: '将摄像头对准 ${AppConfig.appName} 生成的二维码，识别后会自动继续。',
  );
  if (!state.mounted) {
    return;
  }
  state._updateView(() => state._isScanning = false);
  if (link == null || link.trim().isEmpty) {
    return;
  }
  await state._handleScannedLink(link);
}

Future<void> _handleQrScannedLink(
    _QRLoginScreenState state, String link) async {
  final trimmed = link.trim();
  final authState = state.ref.read(authStateProvider);
  if (trimmed.startsWith('happy://terminal?')) {
    if (!authState.isAuthenticated) {
      state._showSnackBar('这是电脑连接二维码，请先恢复账户后再扫描');
      return;
    }
    if (state.mounted) {
      state.context.push(
          '${AppRoutes.terminalConnect}?url=${Uri.encodeComponent(trimmed)}');
    }
    return;
  }
  if (trimmed.startsWith('happy:///account?')) {
    if (!authState.isAuthenticated) {
      state._showSnackBar('这是设备授权二维码，请先恢复账户后再扫描');
      return;
    }
    if (state.mounted) {
      state.context
          .push('${AppRoutes.linkAccount}?url=${Uri.encodeComponent(trimmed)}');
    }
    return;
  }

  final authNotifier = state.ref.read(authStateProvider.notifier);
  await authNotifier.loginWithLink(trimmed);
  final nextState = state.ref.read(authStateProvider);
  if (!state.mounted) {
    return;
  }
  if (nextState.isAuthenticated) {
    state.context.go(AppRoutes.home);
    state._showSnackBar('扫码登录成功');
    return;
  }
  state._showSnackBar(nextState.errorMessage ?? '扫码内容无法用于登录');
}

Future<void> _createQrLoginAccount(_QRLoginScreenState state) async {
  try {
    final authRepository = AuthRepository.instance;
    final crypto = await CryptoService.instance;
    final keyPair = await crypto.generateKeyPair();
    final secretKey = keyPair['secretKey'];
    if (secretKey == null || secretKey.isEmpty) {
      throw Exception('生成密钥失败');
    }
    final authNotifier = state.ref.read(authStateProvider.notifier);
    await authNotifier.loginWithSecretKey(secretKey);
    final authState = state.ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          const SnackBar(
            content: Text('创建账户成功'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
        state.context.go(AppRoutes.home);
      }
      return;
    }

    final qrResponse = await authRepository.generateQRCodeForTerminal();
    final fallbackSecret = qrResponse.secretKey;
    if (fallbackSecret == null || fallbackSecret.isEmpty) {
      throw Exception('生成密钥失败');
    }
    await authRepository.saveSecretKey(fallbackSecret);
    Logger.info('Secret key saved locally');
    await authNotifier.startAccountAuthPolling(
      secretKey: fallbackSecret,
      expiresAt: qrResponse.expiresAt,
    );
    if (state.mounted) {
      await state._showQRCodeDialog(qrResponse.qrData);
    }
  } catch (error) {
    Logger.error('Create account error: $error');
    if (state.mounted) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        SnackBar(
          content: Text('创建账户失败: $error'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

void _showQrLoginSnackBar(_QRLoginScreenState state, String message) {
  if (!state.mounted) {
    return;
  }
  ScaffoldMessenger.of(state.context)
      .showSnackBar(SnackBar(content: Text(message)));
}
