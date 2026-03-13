import 'package:flutter/services.dart';

import '../../shared/utils/extensions.dart';

class HappyLinkService {
  HappyLinkService._();

  static final HappyLinkService instance = HappyLinkService._();

  static const MethodChannel _channel = MethodChannel('happy.linking');

  Future<String?> takePendingLink() async {
    try {
      final link = await _channel.invokeMethod<String>('takePendingLink');
      final trimmed = link?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return null;
      }
      Logger.info('Received pending happy link');
      return trimmed;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      Logger.warning('Failed to read pending happy link: ${error.message}');
      return null;
    }
  }

  bool isTerminalLink(String link) {
    return link.trim().startsWith('happy://terminal?');
  }

  bool isAccountLink(String link) {
    return link.trim().startsWith('happy:///account?');
  }

  bool isRestoreLink(String link) {
    final cleaned = link.trim();
    if (cleaned.isEmpty) {
      return false;
    }
    if (isTerminalLink(cleaned) || isAccountLink(cleaned)) {
      return false;
    }
    return cleaned.startsWith('happy://') ||
        cleaned.startsWith('handy://') ||
        cleaned.startsWith('https://happy.link/');
  }
}
