part of 'encryption_screen.dart';

class _InitialView extends StatelessWidget {
  const _InitialView(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppTheme.brandColor),
            const SizedBox(height: 24),
            Text(
              '加密密钥未生成',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '为了保护您的数据安全，请生成加密密钥对',
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(encryptionStateProvider.notifier).generateKeyPair(),
              icon: const Icon(Icons.vpn_key),
              label: const Text('生成密钥对'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView(this.isOwnKey);

  final bool isOwnKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            isOwnKey ? '正在生成密钥...' : '正在处理加密...',
            style: TextStyle(color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }
}

class _EncryptionStateView extends StatelessWidget {
  const _EncryptionStateView({required this.state, required this.ref});

  final EncryptionState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.isInitial) {
      return _InitialView(ref);
    }
    if (state.isEncrypting) {
      return _LoadingView(state.isOwnKeyEncrypting);
    }
    if (state.isHasKeys) {
      return _HasKeysView(ref);
    }
    if (state.isDecrypted) {
      return _DecryptedView(state.decryptedData!, ref);
    }
    if (state.isError) {
      return _ErrorView(state.errorMessage!, ref);
    }
    return _InitialView(ref);
  }
}
