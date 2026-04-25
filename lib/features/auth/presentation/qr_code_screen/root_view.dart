part of 'qr_code_screen.dart';

Widget _buildQRCodeScaffold(
  _QRCodeScreenState state,
  BuildContext context,
) {
  final authState = state.ref.watch(authStateProvider);
  if (authState.isAuthenticated && state.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        context.go(AppRoutes.home);
      }
    });
  }

  return Scaffold(
    appBar: _buildQRCodeAppBar(state),
    body: state._isManualConfirm
        ? _buildManualConfirmView(state)
        : _buildQRCodeView(state),
  );
}

PreferredSizeWidget _buildQRCodeAppBar(_QRCodeScreenState state) {
  return AppBar(
    title: Text(
      state._isManualConfirm ? '确认登录' : '链接设备',
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    centerTitle: true,
    backgroundColor: AppTheme.surface,
    foregroundColor: AppTheme.textPrimary,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: state._cancel,
    ),
    actions: [
      if (state._qrData != null && !state._isManualConfirm)
        IconButton(
          icon: state._isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.brandColor,
                  ),
                )
              : const Icon(Icons.refresh_outlined),
          onPressed: state._isRefreshing ? null : state._refreshQRCode,
          tooltip: '刷新',
        ),
    ],
  );
}

Widget _buildQRCodeView(_QRCodeScreenState state) {
  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state._errorMessage != null) ...[
            _buildQRCodeErrorCard(state),
            const SizedBox(height: 24),
          ],
          _buildQRCodeInstructionCard(),
          const SizedBox(height: 32),
          if (state._isLoading)
            _buildQRCodeLoadingView()
          else if (state._qrData != null)
            _buildQRCodeCard(state)
          else
            _buildQRCodeEmptyState(state),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () => state.context.push(AppRoutes.restoreManual),
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('使用密钥恢复'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brandColor,
              side: const BorderSide(color: AppTheme.brandColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    ),
  );
}
