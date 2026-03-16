part of 'link_account_screen.dart';

Widget _buildLinkAccountView(_LinkAccountScreenState state) {
  if (state._isLoading) {
    return _buildLinkAccountLoadingView();
  }
  if (state._errorMessage != null) {
    return _buildLinkAccountErrorView(state);
  }
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('链接新设备'),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinkAccountHero(),
            const SizedBox(height: 32),
            const Text(
              '设备链接请求',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '有一台设备请求链接到您的账户。是否批准此请求？',
              style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildLinkAccountKeyCard(state._publicKeyShort ?? 'Unknown'),
            const SizedBox(height: 24),
            _buildLinkAccountSecurityTip(),
            const SizedBox(height: 32),
            _buildLinkAccountActions(state),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLinkAccountLoadingView() {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('链接新设备'),
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.brandColor),
          SizedBox(height: 16),
          Text('正在处理链接请求...',
              style: TextStyle(fontSize: 16, color: AppTheme.neutral600)),
        ],
      ),
    ),
  );
}

Widget _buildLinkAccountErrorView(_LinkAccountScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('链接失败'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 24),
            const Text(
              '处理链接请求时发生错误',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state._errorMessage ?? '未知错误',
              style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(state.context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    ),
  );
}
