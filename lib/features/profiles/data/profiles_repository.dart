import '../../profile/data/profile_repository.dart' as core;
import '../domain/profile_models.dart';

/// Compatibility repository for the legacy `features/profiles` namespace.
///
/// The project already has a canonical `features/profile` module. Reusing it
/// here removes duplicated profile persistence logic while keeping the older
/// API surface available to callers that still import `features/profiles`.
class ProfilesRepository {
  ProfilesRepository({core.ProfileRepository? repository})
      : _repository = repository ?? core.ProfileRepository.instance;

  final core.ProfileRepository _repository;

  Future<ProfileListResponse> listProfiles() async {
    final profiles = await _repository.loadProfilesLocal();
    return ProfileListResponse(items: profiles);
  }

  Future<AIBackendProfile> getProfile(String id) async {
    final profile = await _repository.getProfile(id);
    if (profile == null) {
      throw Exception('Profile not found: $id');
    }
    return profile;
  }

  Future<AIBackendProfile> createProfile(ProfileRequest request) async {
    final profile = request.toProfile(
      profileId: request.id ?? _repository.generateId(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _repository.createProfile(profile);
  }

  Future<AIBackendProfile> updateProfile(
    String id,
    ProfileRequest request,
  ) async {
    final existing = await getProfile(id);
    final updated = request.toProfile(
      profileId: id,
      isBuiltIn: existing.isBuiltIn,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      version: existing.version,
    );
    return _repository.updateProfile(updated);
  }

  Future<void> deleteProfile(String id) {
    return _repository.deleteProfile(id);
  }

  Future<void> setDefaultProfile(String? id) {
    return _repository.saveActiveProfileId(id ?? '');
  }

  Future<String?> loadDefaultProfileId() async {
    final profileId = await _repository.loadActiveProfileId();
    if (profileId == null || profileId.isEmpty) {
      return null;
    }
    return profileId;
  }
}
