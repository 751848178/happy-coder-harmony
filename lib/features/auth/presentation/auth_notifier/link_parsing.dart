part of 'auth_notifier.dart';

String? _parseLinkForSecretKey(AuthNotifier notifier, String linkUrl) {
  try {
    Logger.info('Parsing link: $linkUrl');
    if (linkUrl.startsWith('happy://')) {
      return _parseHappyLink(linkUrl);
    }
    if (linkUrl.startsWith('https://happy.link/')) {
      final value = linkUrl.substring(19);
      Logger.info('Value from happy.link: ${value.length}');
      return _normalizeBase64(value);
    }
    if (linkUrl.startsWith('handy://')) {
      final encodedSecret = linkUrl.substring(8);
      Logger.info('Encoded secret from handy:// link: ${encodedSecret.length}');
      final normalized = _normalizeBase64(encodedSecret);
      final decoded = utf8.decode(base64Decode(normalized));
      Logger.info('Decoded secret key length: ${decoded.length}');
      return _normalizeBase64(decoded);
    }
    if (linkUrl.startsWith('happy:///account?')) {
      return null;
    }
    Logger.error('Invalid link format: $linkUrl');
    return null;
  } catch (e) {
    Logger.error('Parse link error: $e');
    return null;
  }
}

String? _parseHappyLink(String linkUrl) {
  final uri = Uri.tryParse(linkUrl);
  if (uri != null) {
    final queryValue = _extractSecretFromQuery(uri);
    if (queryValue != null) {
      return queryValue;
    }
    if (uri.host.isNotEmpty &&
        uri.host != 'terminal' &&
        uri.host != 'account') {
      Logger.info('Secret from host: ${uri.host.length}');
      return _normalizeBase64(uri.host);
    }
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    if (path.isNotEmpty) {
      Logger.info('Secret from path: ${path.length}');
      return _normalizeBase64(path);
    }
  }

  final value = linkUrl.substring(8);
  Logger.info('Value from happy:// link: ${value.length}');
  return _normalizeBase64(value);
}

String? _extractSecretFromQuery(Uri uri) {
  if (uri.query.isEmpty) {
    return null;
  }
  final secretParam = uri.queryParameters['secret'] ??
      uri.queryParameters['key'] ??
      uri.queryParameters['token'];
  if (secretParam != null && secretParam.isNotEmpty) {
    Logger.info('Secret from query param: ${secretParam.length}');
    return _normalizeBase64(secretParam);
  }
  if (uri.queryParameters.length == 1) {
    final entry = uri.queryParameters.entries.first;
    if (entry.value.isEmpty && entry.key.isNotEmpty) {
      Logger.info('Secret from query key: ${entry.key.length}');
      return _normalizeBase64(entry.key);
    }
  }
  Logger.info('Secret from raw query: ${uri.query.length}');
  return _normalizeBase64(uri.query);
}

String _normalizeBase64(String input) {
  var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
  while (standard.length % 4 != 0) {
    standard += '=';
  }
  return standard;
}

String _toStandardBase64(String input) {
  return _normalizeBase64(input);
}
