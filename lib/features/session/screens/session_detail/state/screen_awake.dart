part of '../session_detail.dart';

extension _SessionScreenStateScreenAwake on _SessionScreenState {
  void _updateScreenAwakePolicy({required bool keepAwake}) {
    if (_desiredScreenAwake == keepAwake && !_screenAwakeUpdateScheduled) {
      return;
    }
    _desiredScreenAwake = keepAwake;
    _screenAwakePolicyEpoch += 1;
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
    final epoch = _screenAwakePolicyEpoch;
    final target = _desiredScreenAwake;
    if (_appliedScreenAwake == target) {
      return;
    }

    final applied = await ScreenAwakeService.instance.setKeepAwake(target);
    if (epoch != _screenAwakePolicyEpoch || target != _desiredScreenAwake) {
      if (!_desiredScreenAwake) {
        await ScreenAwakeService.instance.release();
        _appliedScreenAwake = false;
      } else {
        unawaited(_applyScreenAwakePolicy());
      }
      return;
    }
    _appliedScreenAwake = applied ? target : false;
  }

  Future<void> _releaseScreenAwakePolicy() async {
    _desiredScreenAwake = false;
    _screenAwakePolicyEpoch += 1;
    if (!_appliedScreenAwake) {
      return;
    }
    await ScreenAwakeService.instance.release();
    _appliedScreenAwake = false;
  }
}
