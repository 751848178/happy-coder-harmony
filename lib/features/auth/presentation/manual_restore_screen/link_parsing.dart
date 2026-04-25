part of 'manual_restore_screen.dart';

extension on _ManualRestoreScreenState {
  bool _looksLikeTerminalLink(String input) {
    return input.trim().startsWith('happy://terminal?');
  }

  bool _looksLikeRestoreLink(String input) {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return false;
    }
    if (_looksLikeTerminalLink(cleaned) || _looksLikeAccountAuthLink(cleaned)) {
      return false;
    }
    return cleaned.startsWith('happy://') ||
        cleaned.startsWith('handy://') ||
        cleaned.startsWith('https://happy.link/');
  }

  bool _looksLikeAccountAuthLink(String input) {
    final cleaned = input.trim();
    return cleaned.isNotEmpty &&
        (cleaned.startsWith('base64url=') || cleaned.contains('base64url='));
  }

  bool _looksLikeBase64(String input) {
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=_\-]+$');
    return base64Pattern.hasMatch(input) && input.length >= 16;
  }

  String _formatSecretKey(String key) {
    var cleaned = key.replaceAll(RegExp(r'\s+'), '');
    Logger.info('Formatting secret key: "$cleaned"');
    if (!cleaned.startsWith('happy://')) {
      return cleaned;
    }
    final uri = Uri.tryParse(cleaned);
    if (uri == null) {
      return cleaned;
    }
    Logger.info(
      'Parsed URI - scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}, query: ${uri.query}',
    );
    if (uri.query.isNotEmpty) {
      final secret = uri.queryParameters['secret'] ??
          uri.queryParameters['key'] ??
          uri.queryParameters['token'];
      cleaned = secret ?? uri.query;
      Logger.info('Extracted secret from query: $cleaned');
      return cleaned;
    }
    var path = uri.path;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isNotEmpty) {
      cleaned = path;
      Logger.info('Extracted secret from path: $path');
    }
    Logger.info('Formatted secret key: "$cleaned"');
    return cleaned;
  }
}
