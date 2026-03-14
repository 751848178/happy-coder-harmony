import '../platform/happy_link_bridge.dart';
import '../../shared/utils/extensions.dart';

class HappyLinkService {
  HappyLinkService._();

  static final HappyLinkService instance = HappyLinkService._();

  Future<String?> takePendingLink() async {
    final link = await HappyLinkBridge.instance.takePendingLink();
    final trimmed = link?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    Logger.info('Received pending happy link');
    return trimmed;
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
