part of 'qr_login_screen.dart';

Widget _buildQrLoginScreen(_QRLoginScreenState state) {
  final authState = state.ref.watch(authStateProvider);
  if (authState.isAuthenticated && state.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        state.context.go(AppRoutes.home);
      }
    });
    return const SizedBox.shrink();
  }
  return state._isLandscape(state.context)
      ? _buildQrLoginLandscapeView(state)
      : _buildQrLoginPortraitView(state);
}

Widget _buildQrLoginPortraitView(_QRLoginScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQrLoginBranding(),
              const SizedBox(height: 48),
              _buildQrLoginActions(state),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildQrLoginLandscapeView(_QRLoginScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: Center(child: _QrLoginBranding())),
            const SizedBox(width: 48),
            Expanded(child: Center(child: _buildQrLoginActions(state))),
          ],
        ),
      ),
    ),
  );
}

Widget _buildQrLoginBranding() => const _QrLoginBranding();

Widget _buildQrLoginActions(_QRLoginScreenState state) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildQrLoginActionButton(
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('创建账户'),
        onPressed: state._createAccount,
        filled: true,
      ),
      const SizedBox(height: 16),
      _buildQrLoginActionButton(
        icon: Icon(
          state._isScanning
              ? Icons.qr_code_2_rounded
              : Icons.center_focus_strong_rounded,
        ),
        label: Text(state._isScanning ? '扫码中...' : '扫码登录'),
        onPressed: state._isScanning ? null : state._startScanLogin,
      ),
      const SizedBox(height: 16),
      _buildQrLoginActionButton(
        icon: const Icon(Icons.qr_code_scanner_outlined),
        label: const Text('链接或恢复账户'),
        onPressed: () => state.context.push(AppRoutes.restore),
        outlinedColor: AppTheme.brandColor,
      ),
    ],
  );
}

Widget _buildQrLoginActionButton({
  required Widget icon,
  required Widget label,
  required VoidCallback? onPressed,
  bool filled = false,
  Color? outlinedColor,
}) {
  final borderColor = outlinedColor ?? AppTheme.neutral300;
  final child = SizedBox(
    width: double.infinity,
    child: filled
        ? ElevatedButton.icon(
            icon: icon,
            label: label,
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        : OutlinedButton.icon(
            icon: icon,
            label: label,
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: outlinedColor ?? AppTheme.textPrimary,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
  );
  return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420), child: child);
}

class _QrLoginBranding extends StatelessWidget {
  const _QrLoginBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.code, size: 80, color: AppTheme.brandColor),
        const SizedBox(height: 24),
        const Text(
          AppConfig.appName,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900),
        ),
        const SizedBox(height: 8),
        Text(
          AppConfig.appTagline,
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
