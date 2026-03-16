part of 'profile_repository.dart';

class ProfileResponse {
  const ProfileResponse({
    required this.settings,
    required this.settingsVersion,
  });

  final String settings;
  final int settingsVersion;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      settings: json['settings'] as String,
      settingsVersion: json['settingsVersion'] as int,
    );
  }
}

class UpdateProfileResponse {
  const UpdateProfileResponse({
    required this.success,
    required this.version,
  });

  final bool success;
  final int version;

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['success'] as bool,
      version: json['version'] as int,
    );
  }
}

class Settings {
  const Settings({
    required this.schemaVersion,
    this.activeProfileId,
    this.profiles = const [],
  });

  final int schemaVersion;
  final String? activeProfileId;
  final List<AIProfile> profiles;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'activeProfileId': activeProfileId,
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      schemaVersion: json['schemaVersion'] as int? ?? 2,
      activeProfileId: json['activeProfileId'] as String?,
      profiles: (json['profiles'] as List?)
              ?.map((profile) =>
                  AIProfile.fromJson(profile as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Settings copyWith({
    int? schemaVersion,
    String? activeProfileId,
    List<AIProfile>? profiles,
  }) {
    return Settings(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      profiles: profiles ?? this.profiles,
    );
  }
}
