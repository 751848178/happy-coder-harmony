part of 'device_repository.dart';

Future<List<DeviceInfo>> _getRepositoryDevices(
    DeviceRepository repository) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.get(
      '/v1/devices',
      options: repository._getAuthOptions(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get devices: ${response.statusCode}');
    }
    final devicesJson = response.data['devices'] as List<dynamic>? ?? [];
    return devicesJson
        .map((json) => DeviceInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (error) {
    Logger.error('Get devices failed: $error');
    rethrow;
  }
}

Future<DeviceInfo?> _getCurrentRepositoryDevice(
    DeviceRepository repository) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.get(
      '/v1/device/current',
      options: repository._getAuthOptions(),
    );
    if (response.statusCode == 200) {
      return DeviceInfo.fromJson(response.data as Map<String, dynamic>);
    }
    if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to get current device: ${response.statusCode}');
  } catch (error) {
    Logger.error('Get current device failed: $error');
    rethrow;
  }
}

Future<List<ControlRequest>> _getRepositoryControlRequests(
  DeviceRepository repository,
) async {
  try {
    await repository._updateCredentials();
    final response = await repository._client.get(
      '/v1/device/control/requests',
      options: repository._getAuthOptions(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get control requests: ${response.statusCode}');
    }
    final requestsJson = response.data['requests'] as List<dynamic>? ?? [];
    return requestsJson
        .map((json) => ControlRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (error) {
    Logger.error('Get control requests failed: $error');
    rethrow;
  }
}
