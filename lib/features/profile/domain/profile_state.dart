import 'package:flutter/foundation.dart';
import 'profile_models.dart';

/// Profile state for managing AI backend profiles
@immutable
sealed class ProfileState {
  const ProfileState();

  /// Check if profiles are loaded
  bool get isLoaded => this is ProfileLoaded;

  /// Get list of profiles
  List<AIProfile> get profiles => this is ProfileLoaded
      ? (this as ProfileLoaded).profiles
      : const [];

  /// Get active profile
  AIProfile? get activeProfile => this is ProfileLoaded
      ? (this as ProfileLoaded).activeProfile
      : null;

  /// Get loading state
  bool get isLoading => this is ProfileLoading;

  /// Get error message
  String? get error => this is ProfileErrorState ? (this as ProfileErrorState).message : null;
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Loaded state with profiles
class ProfileLoaded extends ProfileState {
  final List<AIProfile> profiles;
  final String? activeProfileId;
  final String? activeProfileIdFromServer;

  const ProfileLoaded({
    this.profiles = const [],
    this.activeProfileId,
    this.activeProfileIdFromServer,
  });

  AIProfile? get activeProfile {
    if (activeProfileId != null) {
      try {
        return profiles.firstWhere((p) => p.id == activeProfileId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  ProfileLoaded copyWith({
    List<AIProfile>? profiles,
    String? activeProfileId,
    String? activeProfileIdFromServer,
  }) {
    return ProfileLoaded(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      activeProfileIdFromServer:
          activeProfileIdFromServer ?? this.activeProfileIdFromServer,
    );
  }
}

/// Error state
class ProfileErrorState extends ProfileState {
  final String message;

  const ProfileErrorState(this.message);
}

/// Profile saved state (after create/update)
class ProfileSavedState extends ProfileState {
  final AIProfile profile;

  const ProfileSavedState(this.profile);
}

/// Profile deleted state
class ProfileDeletedState extends ProfileState {
  final String profileId;

  const ProfileDeletedState(this.profileId);
}
