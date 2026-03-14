import 'package:flutter/services.dart';

import '../../shared/utils/extensions.dart';

class HappyLinkBridge {
  HappyLinkBridge._();

  static final HappyLinkBridge instance = HappyLinkBridge._();
  static const MethodChannel _channel = MethodChannel('happy.linking');

  Future<String?> takePendingLink() async {
    try {
      return await _channel.invokeMethod<String>('takePendingLink');
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      Logger.warning('Failed to read pending happy link: ${error.message}');
      return null;
    }
  }
}
