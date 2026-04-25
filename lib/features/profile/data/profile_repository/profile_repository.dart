import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/app_config.dart';
import '../../../../shared/utils/extensions.dart';
import '../../domain/profile_models.dart';

part 'local.dart';
part 'models.dart';
part 'remote.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => AppConfig.serverUrl;

  Future<String?> _getToken() => _storage.read(key: 'token');

  Future<Settings?> getSettings() => _getRemoteSettings(this);

  Future<bool> updateSettings(Settings settings, {int? expectedVersion}) =>
      _updateRemoteSettings(this, settings, expectedVersion: expectedVersion);

  Future<void> saveProfilesLocal(List<AIProfile> profiles) =>
      _saveProfilesLocal(this, profiles);

  Future<List<AIProfile>> loadProfilesLocal() => _loadProfilesLocal(this);

  Future<void> saveActiveProfileId(String profileId) =>
      _saveActiveProfileId(this, profileId);

  Future<String?> loadActiveProfileId() => _loadActiveProfileId(this);

  Future<void> clearLocalProfiles() => _clearLocalProfiles(this);

  Future<AIProfile> createProfile(AIProfile profile) =>
      _createLocalProfile(this, profile);

  Future<AIProfile> updateProfile(AIProfile profile) =>
      _updateLocalProfile(this, profile);

  Future<void> deleteProfile(String profileId) =>
      _deleteLocalProfile(this, profileId);

  Future<AIProfile?> getProfile(String profileId) =>
      _getLocalProfile(this, profileId);

  String generateId() => _generateProfileId();
}
