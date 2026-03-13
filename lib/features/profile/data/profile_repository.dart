import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/profile_models.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/utils/extensions.dart';

/// Profile API response models
class ProfileResponse {
  final String settings;
  final int settingsVersion;

  const ProfileResponse({
    required this.settings,
    required this.settingsVersion,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      settings: json['settings'] as String,
      settingsVersion: json['settingsVersion'] as int,
    );
  }
}

class UpdateProfileResponse {
  final bool success;
  final int version;

  const UpdateProfileResponse({
    required this.success,
    required this.version,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['success'] as bool,
      version: json['version'] as int,
    );
  }
}

/// Settings schema (matching Happy Coder's server response)
class Settings {
  final int schemaVersion;
  final String? activeProfileId;
  final List<AIProfile> profiles;

  const Settings({
    required this.schemaVersion,
    this.activeProfileId,
    this.profiles = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'activeProfileId': activeProfileId,
      'profiles': profiles.map((p) => p.toJson()).toList(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      schemaVersion: json['schemaVersion'] as int? ?? 2,
      activeProfileId: json['activeProfileId'] as String?,
      profiles: (json['profiles'] as List?)
              ?.map((p) => AIProfile.fromJson(p as Map<String, dynamic>))
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

/// Profile repository for managing AI backend profiles
class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get base URL from environment
  String get baseUrl => AppConfig.serverUrl;

  /// Get auth token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  /// Fetch profile settings from server
  ///
  /// GET /v1/account/settings
  Future<Settings?> getSettings() async {
    try {
      final token = await _getToken();
      if (token == null) {
        Logger.warning('No auth token found');
        return null;
      }

      final response = await _dio.get(
        '$baseUrl/v1/account/settings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);

        // The settings are encrypted on the server
        // For now, we'll return empty settings (decryption would be needed)
        // In a real implementation, we would decrypt using the encryption key
        Logger.info('Settings retrieved, version: ${profileResponse.settingsVersion}');

        // Return empty settings as placeholder
        // TODO: Implement decryption when encryption key is available
        return const Settings(schemaVersion: 2);
      }

      return null;
    } catch (e) {
      Logger.error('Failed to get settings: $e');
      return null;
    }
  }

  /// Update profile settings on server
  ///
  /// POST /v1/account/settings
  /// Body: { settings: <encrypted settings JSON>, expectedVersion: <version> }
  Future<bool> updateSettings(Settings settings, {int? expectedVersion}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        Logger.warning('No auth token found');
        return false;
      }

      // In a real implementation, we would encrypt the settings
      // For now, we'll send as-is
      final body = {
        'settings': jsonEncode(settings.toJson()),
        if (expectedVersion != null) 'expectedVersion': expectedVersion,
      };

      final response = await _dio.post(
        '$baseUrl/v1/account/settings',
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final updateResponse = UpdateProfileResponse.fromJson(response.data);
        Logger.info('Settings updated, new version: ${updateResponse.version}');
        return updateResponse.success;
      }

      return false;
    } catch (e) {
      Logger.error('Failed to update settings: $e');
      return false;
    }
  }

  /// Save profiles locally (for offline access)
  Future<void> saveProfilesLocal(List<AIProfile> profiles) async {
    try {
      final profilesJson = jsonEncode(profiles.map((p) => p.toJson()).toList());
      await _storage.write(key: 'profiles', value: profilesJson);
      Logger.info('Profiles saved locally');
    } catch (e) {
      Logger.error('Failed to save profiles locally: $e');
    }
  }

  /// Load profiles from local storage
  Future<List<AIProfile>> loadProfilesLocal() async {
    try {
      final profilesJson = await _storage.read(key: 'profiles');
      if (profilesJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(profilesJson);
      return decoded
          .map((p) => AIProfile.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.error('Failed to load profiles locally: $e');
      return [];
    }
  }

  /// Save active profile ID locally
  Future<void> saveActiveProfileId(String profileId) async {
    try {
      await _storage.write(key: 'activeProfileId', value: profileId);
      Logger.info('Active profile saved: $profileId');
    } catch (e) {
      Logger.error('Failed to save active profile ID: $e');
    }
  }

  /// Load active profile ID from local storage
  Future<String?> loadActiveProfileId() async {
    try {
      return await _storage.read(key: 'activeProfileId');
    } catch (e) {
      Logger.error('Failed to load active profile ID: $e');
      return null;
    }
  }

  /// Clear local profile data
  Future<void> clearLocalProfiles() async {
    try {
      await _storage.delete(key: 'profiles');
      await _storage.delete(key: 'activeProfileId');
      Logger.info('Local profiles cleared');
    } catch (e) {
      Logger.error('Failed to clear local profiles: $e');
    }
  }

  /// Create a new profile (local only)
  Future<AIProfile> createProfile(AIProfile profile) async {
    // Save to local storage
    final profiles = await loadProfilesLocal();
    final updatedProfiles = [...profiles, profile];
    await saveProfilesLocal(updatedProfiles);
    return profile;
  }

  /// Update an existing profile (local only)
  Future<AIProfile> updateProfile(AIProfile profile) async {
    final profiles = await loadProfilesLocal();
    final updatedProfiles = profiles
        .map((p) => p.id == profile.id ? profile : p)
        .toList();
    await saveProfilesLocal(updatedProfiles);
    return profile;
  }

  /// Delete a profile (local only)
  Future<void> deleteProfile(String profileId) async {
    final profiles = await loadProfilesLocal();
    final updatedProfiles = profiles.where((p) => p.id != profileId).toList();
    await saveProfilesLocal(updatedProfiles);
  }

  /// Get a specific profile by ID
  Future<AIProfile?> getProfile(String profileId) async {
    final profiles = await loadProfilesLocal();
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (_) {
      return null;
    }
  }

  /// Generate a unique ID for a new profile
  String generateId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${1000 + now.millisecond % 9000}';
  }
}
