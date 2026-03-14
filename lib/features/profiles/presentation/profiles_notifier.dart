import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profiles_repository.dart';
import '../domain/profile_models.dart';

class ProfilesState {
  const ProfilesState({
    this.profiles = const [],
    this.activeProfileId,
    this.isLoading = false,
    this.errorMessage,
  });

  const ProfilesState.initial()
      : profiles = const [],
        activeProfileId = null,
        isLoading = false,
        errorMessage = null;

  final List<AIBackendProfile> profiles;
  final String? activeProfileId;
  final bool isLoading;
  final String? errorMessage;

  static const Object _unset = Object();

  ProfilesState copyWith({
    List<AIBackendProfile>? profiles,
    Object? activeProfileId = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      activeProfileId: identical(activeProfileId, _unset)
          ? this.activeProfileId
          : activeProfileId as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get hasError => errorMessage != null;

  AIBackendProfile? get activeProfile {
    if (activeProfileId == null) {
      return null;
    }

    for (final profile in profiles) {
      if (profile.id == activeProfileId) {
        return profile;
      }
    }
    return null;
  }

  bool isDefault(String id) => activeProfileId == id;
}

class ProfilesNotifier extends StateNotifier<ProfilesState> {
  ProfilesNotifier(this._repository) : super(const ProfilesState.initial());

  final ProfilesRepository _repository;

  Future<void> loadProfiles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.listProfiles();
      final activeProfileId = await _repository.loadDefaultProfileId();
      state = ProfilesState(
        profiles: response.items,
        activeProfileId: activeProfileId,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> createProfile(ProfileRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.createProfile(request);
      state = ProfilesState(
        profiles: [...state.profiles, profile],
        activeProfileId: state.activeProfileId,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> updateProfile(String id, ProfileRequest request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateProfile(id, request);
      final profiles = state.profiles
          .map((profile) => profile.id == id ? updated : profile)
          .toList();
      state = ProfilesState(
        profiles: profiles,
        activeProfileId: state.activeProfileId,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> deleteProfile(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteProfile(id);
      final nextActiveProfileId =
          state.activeProfileId == id ? null : state.activeProfileId;
      if (nextActiveProfileId != state.activeProfileId) {
        await _repository.setDefaultProfile(null);
      }
      state = ProfilesState(
        profiles: state.profiles.where((profile) => profile.id != id).toList(),
        activeProfileId: nextActiveProfileId,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> setDefaultProfile(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.setDefaultProfile(id);
      state = ProfilesState(
        profiles: state.profiles,
        activeProfileId: id,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  AIBackendProfile? get defaultProfile => state.activeProfile;

  bool isDefault(String id) => state.isDefault(id);
}
