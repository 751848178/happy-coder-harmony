import 'dart:io';

import 'package:flutter/foundation.dart';

class HarmonyPlatform {
  const HarmonyPlatform._();

  static bool get isHarmonyOS {
    if (kIsWeb) {
      return false;
    }

    final os = Platform.operatingSystem.toLowerCase();
    if (os == 'ohos' || os == 'harmonyos' || os == 'openharmony') {
      return true;
    }

    final env = Platform.environment;
    return env.containsKey('OHOS') ||
        env.containsKey('HARMONYOS') ||
        env.containsKey('OPENHARMONY');
  }
}
