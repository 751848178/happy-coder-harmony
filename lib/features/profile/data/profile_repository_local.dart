part of 'profile_repository.dart';

Future<void> _saveProfilesLocal(
  ProfileRepository repository,
  List<AIProfile> profiles,
) async {
  try {
    final profilesJson =
        jsonEncode(profiles.map((profile) => profile.toJson()).toList());
    await repository._storage.write(key: 'profiles', value: profilesJson);
    Logger.info('Profiles saved locally');
  } catch (error) {
    Logger.error('Failed to save profiles locally: $error');
  }
}

Future<List<AIProfile>> _loadProfilesLocal(ProfileRepository repository) async {
  try {
    final profilesJson = await repository._storage.read(key: 'profiles');
    if (profilesJson == null) {
      return [];
    }
    final decoded = jsonDecode(profilesJson) as List<dynamic>;
    return decoded
        .map((profile) => AIProfile.fromJson(profile as Map<String, dynamic>))
        .toList();
  } catch (error) {
    Logger.error('Failed to load profiles locally: $error');
    return [];
  }
}

Future<void> _saveActiveProfileId(
  ProfileRepository repository,
  String profileId,
) async {
  try {
    await repository._storage.write(key: 'activeProfileId', value: profileId);
    Logger.info('Active profile saved: $profileId');
  } catch (error) {
    Logger.error('Failed to save active profile ID: $error');
  }
}

Future<String?> _loadActiveProfileId(ProfileRepository repository) async {
  try {
    return await repository._storage.read(key: 'activeProfileId');
  } catch (error) {
    Logger.error('Failed to load active profile ID: $error');
    return null;
  }
}

Future<void> _clearLocalProfiles(ProfileRepository repository) async {
  try {
    await repository._storage.delete(key: 'profiles');
    await repository._storage.delete(key: 'activeProfileId');
    Logger.info('Local profiles cleared');
  } catch (error) {
    Logger.error('Failed to clear local profiles: $error');
  }
}

Future<AIProfile> _createLocalProfile(
  ProfileRepository repository,
  AIProfile profile,
) async {
  final profiles = await repository.loadProfilesLocal();
  final updatedProfiles = [...profiles, profile];
  await repository.saveProfilesLocal(updatedProfiles);
  return profile;
}

Future<AIProfile> _updateLocalProfile(
  ProfileRepository repository,
  AIProfile profile,
) async {
  final profiles = await repository.loadProfilesLocal();
  final updatedProfiles =
      profiles.map((item) => item.id == profile.id ? profile : item).toList();
  await repository.saveProfilesLocal(updatedProfiles);
  return profile;
}

Future<void> _deleteLocalProfile(
  ProfileRepository repository,
  String profileId,
) async {
  final profiles = await repository.loadProfilesLocal();
  final updatedProfiles =
      profiles.where((profile) => profile.id != profileId).toList();
  await repository.saveProfilesLocal(updatedProfiles);
}

Future<AIProfile?> _getLocalProfile(
  ProfileRepository repository,
  String profileId,
) async {
  final profiles = await repository.loadProfilesLocal();
  try {
    return profiles.firstWhere((profile) => profile.id == profileId);
  } catch (_) {
    return null;
  }
}

String _generateProfileId() {
  final now = DateTime.now();
  return '${now.millisecondsSinceEpoch}_${1000 + now.millisecond % 9000}';
}
