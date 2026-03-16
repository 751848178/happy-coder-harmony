import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_models.dart';
import '../domain/profile_state.dart';
import '../data/profile_repository.dart';

/// Profile state notifier for managing AI backend profiles
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;

  /// Load profiles from local storage
  Future<void> loadProfiles() async {
    state = const ProfileLoading();

    try {
      final profiles = await _repository.loadProfilesLocal();
      final activeProfileId = await _repository.loadActiveProfileId();

      state = ProfileLoaded(
        profiles: profiles.isEmpty ? BuiltInProfiles.all() : profiles,
        activeProfileId: activeProfileId,
      );

      // Load from server if authenticated
      // This will be implemented when server sync is ready
    } catch (e) {
      state = ProfileErrorState('Failed to load profiles');
    }
  }

  /// Create a new profile
  Future<void> createProfile(AIProfile profile) async {
    try {
      final newProfile = profile.copyWith(
        id: _repository.generateId(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createProfile(newProfile);

      final currentState = state;
      if (currentState is ProfileLoaded) {
        state = currentState.copyWith(
          profiles: [...currentState.profiles, newProfile],
        );
      }

      state = ProfileSavedState(newProfile);
    } catch (e) {
      state = ProfileErrorState('Failed to create profile');
    }
  }

  /// Update an existing profile
  Future<void> updateProfile(AIProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      await _repository.updateProfile(updatedProfile);

      final currentState = state;
      if (currentState is ProfileLoaded) {
        state = currentState.copyWith(
          profiles: currentState.profiles
              .map((p) => p.id == profile.id ? updatedProfile : p)
              .toList(),
        );
      }

      state = ProfileSavedState(updatedProfile);
    } catch (e) {
      state = ProfileErrorState('Failed to update profile');
    }
  }

  /// Delete a profile
  Future<void> deleteProfile(String profileId) async {
    try {
      await _repository.deleteProfile(profileId);

      final currentState = state;
      if (currentState is ProfileLoaded) {
        final updatedProfiles =
            currentState.profiles.where((p) => p.id != profileId).toList();

        // If the deleted profile was active, clear the active ID
        String? newActiveId;
        if (currentState.activeProfileId == profileId) {
          newActiveId = null;
          await _repository.saveActiveProfileId('');
        }

        state = currentState.copyWith(
          profiles: updatedProfiles,
          activeProfileId: newActiveId,
        );
      }

      state = ProfileDeletedState(profileId);
    } catch (e) {
      state = ProfileErrorState('Failed to delete profile');
    }
  }

  /// Set active profile
  Future<void> setActiveProfile(String profileId) async {
    try {
      await _repository.saveActiveProfileId(profileId);

      final currentState = state;
      if (currentState is ProfileLoaded) {
        state = currentState.copyWith(activeProfileId: profileId);
      }
    } catch (e) {
      state = ProfileErrorState('Failed to set active profile');
    }
  }

  /// Clear all profiles (for testing/reset)
  Future<void> clearProfiles() async {
    try {
      await _repository.clearLocalProfiles();
      state = ProfileLoaded(
        profiles: BuiltInProfiles.all(),
      );
    } catch (e) {
      state = ProfileErrorState('Failed to clear profiles');
    }
  }

  /// Ensure built-in profiles are loaded
  Future<void> ensureBuiltInProfiles() async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        final currentProfileIds = currentState.profiles.map((p) => p.id).toSet();
        final missingBuiltIns = BuiltInProfiles.all()
            .where((profile) => !currentProfileIds.contains(profile.id))
            .toList();
        if (missingBuiltIns.isEmpty) {
          return;
        }

        final newProfiles = <AIProfile>[];
        for (final builtIn in missingBuiltIns) {
          final newProfile = builtIn.copyWith(id: builtIn.id);
          await _repository.createProfile(newProfile);
          newProfiles.add(newProfile);
        }

        state = currentState.copyWith(
          profiles: [...currentState.profiles, ...newProfiles],
        );
      }
    } catch (e) {
      // Silently fail - built-in profiles should be available but not critical
    }
  }

  /// Clone a profile
  Future<void> cloneProfile(AIProfile profile) async {
    try {
      final clonedProfile = profile.copyWith(
        id: _repository.generateId(),
        name: '${profile.name} (副本)',
        isBuiltIn: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createProfile(clonedProfile);

      final currentState = state;
      if (currentState is ProfileLoaded) {
        state = currentState.copyWith(
          profiles: [...currentState.profiles, clonedProfile],
        );
      }

      state = ProfileSavedState(clonedProfile);
    } catch (e) {
      state = ProfileErrorState('Failed to clone profile');
    }
  }
}
