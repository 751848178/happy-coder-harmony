part of 'link_account_screen.dart';

Future<void> _processLinkAccountUrl(_LinkAccountScreenState state) async {
  try {
    final authState = state.ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null ||
        credentials.secret == null ||
        credentials.secret!.isEmpty) {
      state._updateView(() {
        state._errorMessage = '未找到凭证，请先登录';
        state._isLoading = false;
      });
      return;
    }

    final authUrl = state.widget.authUrl ?? '';
    Logger.info('Processing auth URL: $authUrl');
    final publicKeyBase64Url = _extractLinkAccountPublicKey(authUrl);
    final publicKeyBase64 = CryptoService.base64UrlDecode(publicKeyBase64Url);
    state._updateView(() {
      state._publicKey = publicKeyBase64;
      state._publicKeyShort = publicKeyBase64Url.length > 40
          ? '${publicKeyBase64Url.substring(0, 20)}...${publicKeyBase64Url.substring(publicKeyBase64Url.length - 20)}'
          : publicKeyBase64Url;
      state._isLoading = false;
    });
    Logger.info('Public key extracted: ${state._publicKeyShort}');
  } catch (error) {
    state._updateView(() {
      state._errorMessage = '处理认证链接失败: $error';
      state._isLoading = false;
    });
    Logger.error('Process auth URL error: $error');
  }
}

String _extractLinkAccountPublicKey(String authUrl) {
  if (!authUrl.startsWith('happy:///account?')) {
    return authUrl;
  }
  final uri = Uri.tryParse(authUrl);
  if (uri != null && uri.queryParameters.containsKey('base64url')) {
    return uri.queryParameters['base64url']!;
  }
  final paramStart = authUrl.indexOf('base64url=');
  if (paramStart > 0) {
    return authUrl.substring(paramStart + 10);
  }
  throw Exception('无法解析 base64url 参数');
}

Future<void> _approveLinkAccount(_LinkAccountScreenState state) async {
  if (state._publicKey == null || state._isProcessing) {
    return;
  }
  state._updateView(() {
    state._isProcessing = true;
    state._errorMessage = null;
  });

  try {
    final authNotifier = state.ref.read(authStateProvider.notifier);
    final success = await authNotifier.linkAccount(state._publicKey!);
    if (success && state.mounted) {
      Navigator.of(state.context).pop();
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(
          content: Text('设备链接成功'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }
    state._updateView(() {
      state._errorMessage = '链接失败，请重试';
      state._isProcessing = false;
    });
  } catch (error) {
    state._updateView(() {
      state._errorMessage = '链接失败: $error';
      state._isProcessing = false;
    });
    Logger.error('Approve link error: $error');
  }
}
