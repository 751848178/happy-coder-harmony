part of 'profile_repository.dart';

Future<Settings?> _getRemoteSettings(ProfileRepository repository) async {
  try {
    final token = await repository._getToken();
    if (token == null) {
      Logger.warning('No auth token found');
      return null;
    }
    final response = await repository._dio.get(
      '${repository.baseUrl}/v1/account/settings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      return null;
    }
    final profileResponse = ProfileResponse.fromJson(response.data);
    Logger.info(
        'Settings retrieved, version: ${profileResponse.settingsVersion}');
    return const Settings(schemaVersion: 2);
  } catch (error) {
    Logger.error('Failed to get settings: $error');
    return null;
  }
}

Future<bool> _updateRemoteSettings(
  ProfileRepository repository,
  Settings settings, {
  int? expectedVersion,
}) async {
  try {
    final token = await repository._getToken();
    if (token == null) {
      Logger.warning('No auth token found');
      return false;
    }
    final body = {
      'settings': jsonEncode(settings.toJson()),
      if (expectedVersion != null) 'expectedVersion': expectedVersion,
    };
    final response = await repository._dio.post(
      '${repository.baseUrl}/v1/account/settings',
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      return false;
    }
    final updateResponse = UpdateProfileResponse.fromJson(response.data);
    Logger.info('Settings updated, new version: ${updateResponse.version}');
    return updateResponse.success;
  } catch (error) {
    Logger.error('Failed to update settings: $error');
    return false;
  }
}
