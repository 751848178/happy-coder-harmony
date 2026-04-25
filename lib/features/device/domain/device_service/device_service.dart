import 'dart:async';

import '../../../../harmony/harmony_bridge.dart';
import '../../../../shared/utils/extensions.dart';
import '../../data/device_repository.dart';
import '../device_models.dart';

part 'control.dart';
part 'timers.dart';

class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  static const int controlTimeoutSeconds = 300;

  late DeviceRepository _repository;
  ControlState _controlState = const ControlState();
  final _stateController = StreamController<ControlState>.broadcast();
  final _requestController = StreamController<ControlRequest>.broadcast();
  Timer? _controlTimeoutTimer;
  Timer? _pingTimer;

  Stream<ControlState> get controlStateStream => _stateController.stream;
  Stream<ControlRequest> get requestStream => _requestController.stream;

  Future<void> initialize() async {
    _repository = DeviceRepository.instance;
    await _repository.initialize();
    Logger.info('Device service initialized');
  }

  Future<bool> requestControl(String targetDeviceId) =>
      _requestDeviceServiceControl(this, targetDeviceId);

  Future<void> releaseControl() => _releaseDeviceServiceControl(this);

  Future<void> handleControlRequest(ControlRequest request) =>
      _handleDeviceControlRequest(this, request);

  Future<void> approveControlRequest(String requestId) =>
      _approveDeviceServiceControlRequest(this, requestId);

  Future<void> rejectControlRequest(String requestId, {String? reason}) =>
      _rejectDeviceServiceControlRequest(this, requestId, reason: reason);

  void startKeyboardListener() => _startDeviceKeyboardListener(this);

  void stopKeyboardListener() => Logger.info('Stopping keyboard listener');

  void setState(ControlState newState) {
    _controlState = newState;
    _stateController.add(newState);
    Logger.debug('Device state changed: ${newState.deviceStatus}');
  }

  Future<List<DeviceInfo>> getDevices() => _repository.getDevices();

  Future<DeviceInfo?> getCurrentDevice() => _repository.getCurrentDevice();

  void dispose() {
    _stopDeviceControlTimeout(this);
    _stopDevicePingTimer(this);
    stopKeyboardListener();
    _stateController.close();
    _requestController.close();
  }
}
