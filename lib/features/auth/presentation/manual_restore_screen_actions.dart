part of 'manual_restore_screen.dart';

Future<void> _restoreManualAccount(_ManualRestoreScreenState state) async {
  final secretKey = state._secretKeyController.text.trim();
  if (secretKey.isEmpty) {
    state._updateView(() => state._errorMessage = '请输入 Secret Key');
    return;
  }
  if (state._looksLikeTerminalLink(secretKey)) {
    if (state.mounted) {
      state.context.push(
        '${AppRoutes.terminalConnect}?url=${Uri.encodeComponent(secretKey)}',
      );
    }
    return;
  }

  final isRestoreLink = state._looksLikeRestoreLink(secretKey);
  final formattedKey = state._formatSecretKey(secretKey);
  if (state._looksLikeAccountAuthLink(formattedKey)) {
    state._updateView(() {
      state._errorMessage = '这是授权链接，不是 Secret Key，请使用终端生成的 Secret Key';
    });
    return;
  }

  state._updateView(() {
    state._isRestoring = true;
    state._errorMessage = null;
  });

  try {
    final authNotifier = state.ref.read(authStateProvider.notifier);
    if (isRestoreLink) {
      await authNotifier.loginWithLink(secretKey);
    } else {
      final base64Secret = state._processSecretKey(formattedKey);
      Logger.info('Secret key processed: ${base64Secret.substring(0, 16)}...');
      final authRepository = AuthRepository.instance;
      await authRepository.loginWithSecret(base64Secret);
      await authNotifier.loginWithHappySecret(base64Secret);
    }

    final authState = state.ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      throw Exception(authState.errorMessage ?? '恢复失败');
    }

    if (!state.mounted) {
      return;
    }
    state.context.go(AppRoutes.home);
    ScaffoldMessenger.of(state.context).showSnackBar(
      const SnackBar(
        content: Text('账户恢复成功'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  } catch (error) {
    state._updateView(() {
      state._errorMessage = '恢复失败: $error';
      state._isRestoring = false;
    });
  }
}
