import 'package:flutter/services.dart';

import '../../harmony/src/harmony_platform.dart';
import '../../shared/utils/extensions.dart';

class ScreenAwakeBridge {
  ScreenAwakeBridge._();

  static final ScreenAwakeBridge instance = ScreenAwakeBridge._();
  static const MethodChannel _channel = MethodChannel('happy.screen_awake');

  Future<bool> setKeepScreenOn(bool enabled) async {
    if (!HarmonyPlatform.isHarmonyOS) {
      return false;
    }
    try {
      return (await _channel.invokeMethod<bool>(
            'setKeepScreenOn',
            {'enabled': enabled},
          )) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      final message = error.message ?? error.code;
      Logger.warning('Failed to set keep-screen-on on HarmonyOS: $message');
      return false;
    } catch (error) {
      Logger.warning('Failed to set keep-screen-on on HarmonyOS: $error');
      return false;
    }
  }
}
