import 'package:wakelock_plus/wakelock_plus.dart';

import '../../harmony/src/harmony_platform.dart';
import '../../shared/utils/extensions.dart';
import 'screen_awake_bridge.dart';

class ScreenAwakeService {
  ScreenAwakeService._();

  static final ScreenAwakeService instance = ScreenAwakeService._();

  Future<bool> setKeepAwake(bool enabled) async {
    if (HarmonyPlatform.isHarmonyOS) {
      return ScreenAwakeBridge.instance.setKeepScreenOn(enabled);
    }
    try {
      await WakelockPlus.toggle(enable: enabled);
      return enabled;
    } catch (error) {
      Logger.warning('Failed to toggle keep-screen-awake: $error');
      return false;
    }
  }

  Future<void> release() async {
    await setKeepAwake(false);
  }
}
