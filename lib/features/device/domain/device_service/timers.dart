part of 'device_service.dart';

void _startDeviceControlTimeout(DeviceService service) {
  _stopDeviceControlTimeout(service);
  service._controlTimeoutTimer = Timer(
    const Duration(seconds: DeviceService.controlTimeoutSeconds),
    () {
      Logger.info('Control timeout reached');
      service.releaseControl();
    },
  );
  Logger.info(
    'Control timeout timer started: ${DeviceService.controlTimeoutSeconds} seconds',
  );
}

void _stopDeviceControlTimeout(DeviceService service) {
  service._controlTimeoutTimer?.cancel();
  service._controlTimeoutTimer = null;
}

void _startDevicePingTimer(DeviceService service) {
  _stopDevicePingTimer(service);
  service._pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    service._repository.sendControlPing();
  });
  Logger.info('Ping timer started');
}

void _stopDevicePingTimer(DeviceService service) {
  service._pingTimer?.cancel();
  service._pingTimer = null;
}
