import 'dart:async';

import '../../../shared/utils/extensions.dart';
import '../../../harmony/harmony_bridge.dart';
import '../data/device_repository.dart';
import 'device_models.dart';

/// 设备控制服务
///
/// 管理设备间的控制权切换
class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  late DeviceRepository _repository;

  // 控制权状态
  ControlState _controlState = const ControlState();

  // 状态流
  final _stateController = StreamController<ControlState>.broadcast();
  final _requestController = StreamController<ControlRequest>.broadcast();

  // 控制权持有定时器
  Timer? _controlTimeoutTimer;
  Timer? _pingTimer;

  // 控制权超时时间（秒）
  static const int _controlTimeoutSeconds = 300; // 5分钟

  /// 控制权状态流
  Stream<ControlState> get controlStateStream => _stateController.stream;

  /// 控制权请求流
  Stream<ControlRequest> get requestStream => _requestController.stream;

  /// 初始化服务
  Future<void> initialize() async {
    _repository = DeviceRepository.instance;
    await _repository.initialize();
    Logger.info('Device service initialized');
  }

  /// 请求控制权
  Future<bool> requestControl(String targetDeviceId) async {
    if (_controlState.hasControl) {
      Logger.warning('Already has control, skipping request');
      return true;
    }

    Logger.info('Requesting control of device: $targetDeviceId');

    setState(const ControlState(deviceStatus: DeviceStatus.requestingControl));

    try {
      final success = await _repository.requestControl(targetDeviceId);
      if (success) {
        // 启动超时定时器
        _startControlTimeout();

        // 启动心跳
        _startPingTimer();

        setState(ControlState(
          deviceStatus: DeviceStatus.hasControl,
          controlAcquiredAt: DateTime.now(),
        ));

        Logger.info('Control acquired');
      } else {
        setState(const ControlState(deviceStatus: DeviceStatus.idle));
      }
      return success;
    } catch (e) {
      Logger.error('Failed to request control: $e');
      setState(const ControlState(deviceStatus: DeviceStatus.idle));
      return false;
    }
  }

  /// 释放控制权
  Future<void> releaseControl() async {
    if (!_controlState.hasControl) {
      Logger.warning('No control to release');
      return;
    }

    Logger.info('Releasing control');

    try {
      await _repository.releaseControl();
      _stopControlTimeout();
      _stopPingTimer();

      setState(const ControlState(deviceStatus: DeviceStatus.idle));

      Logger.info('Control released');
    } catch (e) {
      Logger.error('Failed to release control: $e');
      rethrow;
    }
  }

  /// 处理控制权请求
  Future<void> handleControlRequest(ControlRequest request) async {
    Logger.info('Handling control request: ${request.requestingDeviceName}');

    // 添加到待处理队列
    _requestController.add(request);

    setState(_controlState.copyWith(pendingRequest: request));

    // TODO: 显示控制权请求对话框
    // 通过 Stream 发送请求，UI 监听并显示对话框
  }

  /// 批准控制权请求
  Future<void> approveControlRequest(String requestId) async {
    Logger.info('Approving control request: $requestId');

    try {
      await _repository.approveControlRequest(requestId);

      // 如果有控制权，释放它
      if (_controlState.hasControl) {
        await releaseControl();
      }

      setState(const ControlState(deviceStatus: DeviceStatus.controlTaken));

      Logger.info('Control request approved');
    } catch (e) {
      Logger.error('Failed to approve control request: $e');
      rethrow;
    }
  }

  /// 拒绝控制权请求
  Future<void> rejectControlRequest(String requestId, {String? reason}) async {
    Logger.info('Rejecting control request: $requestId${reason != null ? ', reason: $reason' : ''}');

    try {
      await _repository.rejectControlRequest(requestId, reason: reason);

      setState(ControlState(
        deviceStatus: _controlState.deviceStatus,
        pendingRequest: null,
      ));

      Logger.info('Control request rejected');
    } catch (e) {
      Logger.error('Failed to reject control request: $e');
      rethrow;
    }
  }

  /// 监听键盘事件（按下任意键切换回电脑）
  void startKeyboardListener() {
    Logger.info('Starting keyboard listener');

    // 在 HarmonyOS 上使用原生方法
    if (HarmonyBridge.isHarmonyOS) {
      // TODO: Implement keyboard listener through HarmonyBridge
      Logger.info('Keyboard listener implementation pending for HarmonyOS');
    } else {
      // 非 HarmonyOS 平台，使用 RawKeyboardListener
      // 注意：实际实现需要在主界面添加 RawKeyboardListener
      Logger.info('Keyboard listener not implemented for this platform');
    }
  }

  /// 停止键盘监听
  void stopKeyboardListener() {
    Logger.info('Stopping keyboard listener');
    // TODO: Implement stop keyboard listener
  }

  /// 启动控制权超时定时器
  void _startControlTimeout() {
    _stopControlTimeout();

    _controlTimeoutTimer = Timer(const Duration(seconds: _controlTimeoutSeconds), () {
      Logger.info('Control timeout reached');
      releaseControl();
    });

    Logger.info('Control timeout timer started: $_controlTimeoutSeconds seconds');
  }

  /// 停止控制权超时定时器
  void _stopControlTimeout() {
    _controlTimeoutTimer?.cancel();
    _controlTimeoutTimer = null;
  }

  /// 启动心跳定时器
  void _startPingTimer() {
    _stopPingTimer();

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _repository.sendControlPing();
    });

    Logger.info('Ping timer started');
  }

  /// 停止心跳定时器
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// 设置状态
  void setState(ControlState newState) {
    _controlState = newState;
    _stateController.add(newState);
    Logger.debug('Device state changed: ${newState.deviceStatus}');
  }

  /// 获取设备列表
  Future<List<DeviceInfo>> getDevices() async {
    return await _repository.getDevices();
  }

  /// 获取当前设备信息
  Future<DeviceInfo?> getCurrentDevice() async {
    return await _repository.getCurrentDevice();
  }

  /// 释放资源
  void dispose() {
    _stopControlTimeout();
    _stopPingTimer();
    stopKeyboardListener();
    _stateController.close();
    _requestController.close();
  }
}
