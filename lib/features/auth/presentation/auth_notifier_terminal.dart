part of 'auth_notifier.dart';

Future<bool> _connectTerminal(AuthNotifier notifier, String authUrl) async {
  final credentials = notifier._currentCredentials ??
      await notifier._authRepository.getCredentials();
  if (credentials == null ||
      credentials.secret == null ||
      credentials.secret!.isEmpty) {
    throw Exception('未找到凭证，请先登录');
  }

  final publicKeyBytes = _parseTerminalPublicKey(authUrl);
  if (publicKeyBytes == null) {
    throw Exception('终端链接格式不正确');
  }

  final publicKeyBase64 = base64Encode(publicKeyBytes);
  final crypto = await CryptoService.instance;
  final secretBytes = CryptoService.decodeBase64Flexible(credentials.secret!);
  final responseV1 = await crypto.encryptBoxBundle(secretBytes, publicKeyBytes);
  final contentPublicKey =
      await crypto.deriveHappyCoderContentPublicKey(credentials.secret!);
  final v2Payload = Uint8List(1 + contentPublicKey.length)
    ..[0] = 0
    ..setAll(1, contentPublicKey);
  final responseV2 = await crypto.encryptBoxBundle(v2Payload, publicKeyBytes);

  final TerminalAuthStatusResponse? status =
      await notifier._authRepository.getTerminalAuthStatus(publicKeyBase64);
  if (status == null) {
    throw Exception(
      '无法获取终端认证状态，请确认手机与 PC CLI 使用同一个 Happy Server：${AppConfig.serverUrl}',
    );
  }
  if (status.status == TerminalAuthStatus.authorized ||
      status.status == TerminalAuthStatus.notFound) {
    return true;
  }

  final responseBytes = status.supportsV2 ? responseV2 : responseV1;
  final success = await notifier._authRepository.approveTerminalAuth(
    publicKey: publicKeyBase64,
    response: base64Encode(responseBytes),
  );
  if (!success) {
    throw Exception('终端连接失败');
  }
  await _restoreStoredAuthenticatedCredentials(notifier);
  return true;
}

Future<bool> _linkAccount(AuthNotifier notifier, String authUrlOrKey) async {
  notifier._updateState(AuthState.loading);
  try {
    final credentials = await notifier._authRepository.getCredentials();
    if (credentials == null ||
        credentials.secret == null ||
        credentials.secret!.isEmpty) {
      notifier._updateState(AuthState.error('No credentials available'));
      return false;
    }

    final publicKeyBase64Url = _extractAccountPublicKey(authUrlOrKey);
    Logger.info(
      'Linking account with public key (base64url): $publicKeyBase64Url',
    );
    final crypto = await CryptoService.instance;
    final publicKeyBase64 = CryptoService.base64UrlDecode(publicKeyBase64Url);
    Logger.info('Linking account with public key (base64): $publicKeyBase64');
    final encryptedResponse = await crypto.cryptoBoxForLink(
      credentials.secret!,
      publicKeyBase64,
      credentials.secret!,
    );
    if (encryptedResponse == null) {
      notifier._updateState(
        AuthState.error('Encryption failed - sodium not available'),
      );
      return false;
    }

    final success = await notifier._authRepository.approveAccountAuth(
      publicKey: publicKeyBase64,
      response: encryptedResponse,
      credentials: credentials,
    );
    final syncedCredentials =
        success ? await _restoreStoredAuthenticatedCredentials(notifier) : null;
    notifier._updateState(
      success
          ? AuthState.authenticated(
              credentials: syncedCredentials ?? credentials,
            )
          : AuthState.error('Failed to link account'),
    );
    if (success) {
      Logger.info('Account linked successfully');
    }
    return success;
  } catch (e) {
    notifier._updateState(AuthState.error('Failed to link account: $e'));
    Logger.error('Link account error: $e');
    return false;
  }
}

Uint8List? _parseTerminalPublicKey(String authUrl) {
  final cleaned = authUrl.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  late String value;
  if (cleaned.startsWith('happy://terminal?')) {
    final uri = Uri.tryParse(cleaned);
    if (uri != null && uri.query.isNotEmpty) {
      value = uri.queryParameters['publicKey'] ??
          uri.queryParameters['key'] ??
          uri.queryParameters['token'] ??
          '';
      if (value.isEmpty && uri.queryParameters.length == 1) {
        final entry = uri.queryParameters.entries.first;
        if (entry.value.isEmpty && entry.key.isNotEmpty) {
          value = entry.key;
        }
      }
      if (value.isEmpty) {
        value = uri.query;
      }
    } else {
      value = cleaned.substring('happy://terminal?'.length);
    }
  } else {
    value = cleaned;
  }
  if (value.isEmpty) {
    return null;
  }
  return _decodeBase64Flexible(value);
}

String _extractAccountPublicKey(String authUrlOrKey) {
  if (!authUrlOrKey.startsWith('happy:///account?')) {
    return authUrlOrKey;
  }
  final uri = Uri.tryParse(authUrlOrKey);
  if (uri != null && uri.queryParameters.containsKey('base64url')) {
    return uri.queryParameters['base64url']!;
  }
  final paramStart = authUrlOrKey.indexOf('base64url=');
  if (paramStart > 0) {
    return authUrlOrKey.substring(paramStart + 10);
  }
  throw Exception('Could not parse base64url parameter from URL');
}

Uint8List _decodeBase64Flexible(String input) {
  return base64Decode(_normalizeBase64(input));
}
