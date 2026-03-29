part of 'session_screen.dart';

extension _SessionScreenStateScreenAwake on _SessionScreenState {
  void _updateScreenAwakePolicy({required bool keepAwake}) {
    if (_desiredScreenAwake == keepAwake && !_screenAwakeUpdateScheduled) {
      return;
    }
    _desiredScreenAwake = keepAwake;
    if (_screenAwakeUpdateScheduled) {
      return;
    }
    _screenAwakeUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenAwakeUpdateScheduled = false;
      unawaited(_applyScreenAwakePolicy());
    });
  }

  Future<void> _applyScreenAwakePolicy() async {
    final target = _desiredScreenAwake;
    if (_appliedScreenAwake == target) {
      return;
    }
    if (HarmonyPlatform.isHarmonyOS) {
      final applied = await ScreenAwakeBridge.instance.setKeepScreenOn(target);
      _appliedScreenAwake = applied ? target : false;
      return;
    }
    try {
      await WakelockPlus.toggle(enable: target);
      _appliedScreenAwake = target;
    } catch (_) {
      // Unsupported platforms should safely ignore wake-lock requests.
      _appliedScreenAwake = false;
    }
  }

  Future<void> _releaseScreenAwakePolicy() async {
    _desiredScreenAwake = false;
    if (!_appliedScreenAwake) {
      return;
    }
    if (HarmonyPlatform.isHarmonyOS) {
      await ScreenAwakeBridge.instance.setKeepScreenOn(false);
      _appliedScreenAwake = false;
      return;
    }
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Best effort release only.
    } finally {
      _appliedScreenAwake = false;
    }
  }
}
