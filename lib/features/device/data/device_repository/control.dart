part of 'device_repository.dart';

Future<bool> _requestDeviceControl(
  DeviceRepository repository,
  String targetDeviceId,
) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.post(
      '/v1/device/control/request',
      options: repository._getAuthOptions(),
      data: {'targetDeviceId': targetDeviceId},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      Logger.info('Control request sent');
      return true;
    }
    throw Exception('Failed to request control: ${response.statusCode}');
  } on DioException catch (error) {
    Logger.error('Request control failed: ${error.message}');
    rethrow;
  }
}

Future<void> _releaseDeviceControl(DeviceRepository repository) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.post(
      '/v1/device/control/release',
      options: repository._getAuthOptions(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to release control: ${response.statusCode}');
    }
    Logger.info('Control released');
  } catch (error) {
    Logger.error('Release control failed: $error');
    rethrow;
  }
}

Future<void> _approveDeviceControlRequest(
  DeviceRepository repository,
  String requestId,
) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.post(
      '/v1/device/control/$requestId/approve',
      options: repository._getAuthOptions(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to approve control: ${response.statusCode}');
    }
    Logger.info('Control request approved');
  } catch (error) {
    Logger.error('Approve control failed: $error');
    rethrow;
  }
}

Future<void> _rejectDeviceControlRequest(
  DeviceRepository repository,
  String requestId, {
  String? reason,
}) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.post(
      '/v1/device/control/$requestId/reject',
      options: repository._getAuthOptions(),
      data: reason != null ? {'reason': reason} : null,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to reject control: ${response.statusCode}');
    }
    Logger.info('Control request rejected');
  } catch (error) {
    Logger.error('Reject control failed: $error');
    rethrow;
  }
}

Future<void> _sendDeviceControlPing(DeviceRepository repository) async {
  try {
    await repository._updateCredentials();
    await repository._client.post(
      '/v1/device/control/ping',
      options: repository._getAuthOptions(),
    );
    Logger.debug('Control ping sent');
  } catch (error) {
    Logger.warning('Ping failed: $error');
  }
}
