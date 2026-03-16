part of 'device_service.dart';

Future<bool> _requestDeviceServiceControl(
  DeviceService service,
  String targetDeviceId,
) async {
  if (service._controlState.hasControl) {
    Logger.warning('Already has control, skipping request');
    return true;
  }
  Logger.info('Requesting control of device: $targetDeviceId');
  service.setState(
      const ControlState(deviceStatus: DeviceStatus.requestingControl));
  try {
    final success = await service._repository.requestControl(targetDeviceId);
    if (!success) {
      service.setState(const ControlState(deviceStatus: DeviceStatus.idle));
      return false;
    }
    _startDeviceControlTimeout(service);
    _startDevicePingTimer(service);
    service.setState(
      ControlState(
        deviceStatus: DeviceStatus.hasControl,
        controlAcquiredAt: DateTime.now(),
      ),
    );
    Logger.info('Control acquired');
    return true;
  } catch (error) {
    Logger.error('Failed to request control: $error');
    service.setState(const ControlState(deviceStatus: DeviceStatus.idle));
    return false;
  }
}

Future<void> _releaseDeviceServiceControl(DeviceService service) async {
  if (!service._controlState.hasControl) {
    Logger.warning('No control to release');
    return;
  }
  Logger.info('Releasing control');
  try {
    await service._repository.releaseControl();
    _stopDeviceControlTimeout(service);
    _stopDevicePingTimer(service);
    service.setState(const ControlState(deviceStatus: DeviceStatus.idle));
    Logger.info('Control released');
  } catch (error) {
    Logger.error('Failed to release control: $error');
    rethrow;
  }
}

Future<void> _handleDeviceControlRequest(
  DeviceService service,
  ControlRequest request,
) async {
  Logger.info('Handling control request: ${request.requestingDeviceName}');
  service._requestController.add(request);
  service.setState(service._controlState.copyWith(pendingRequest: request));
}

Future<void> _approveDeviceServiceControlRequest(
  DeviceService service,
  String requestId,
) async {
  Logger.info('Approving control request: $requestId');
  try {
    await service._repository.approveControlRequest(requestId);
    if (service._controlState.hasControl) {
      await service.releaseControl();
    }
    service
        .setState(const ControlState(deviceStatus: DeviceStatus.controlTaken));
    Logger.info('Control request approved');
  } catch (error) {
    Logger.error('Failed to approve control request: $error');
    rethrow;
  }
}

Future<void> _rejectDeviceServiceControlRequest(
  DeviceService service,
  String requestId, {
  String? reason,
}) async {
  Logger.info(
      'Rejecting control request: $requestId${reason != null ? ', reason: $reason' : ''}');
  try {
    await service._repository.rejectControlRequest(requestId, reason: reason);
    service.setState(
      ControlState(
        deviceStatus: service._controlState.deviceStatus,
        pendingRequest: null,
      ),
    );
    Logger.info('Control request rejected');
  } catch (error) {
    Logger.error('Failed to reject control request: $error');
    rethrow;
  }
}

void _startDeviceKeyboardListener(DeviceService service) {
  Logger.info('Starting keyboard listener');
  if (HarmonyBridge.isHarmonyOS) {
    Logger.info('Keyboard listener implementation pending for HarmonyOS');
    return;
  }
  Logger.info('Keyboard listener not implemented for this platform');
}
