import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/api_service.dart';
import '../domain/profile_models.dart';

/// AI Backend Profiles Repository
///
/// 处理 AI 后端配置档案的所有数据操作
class ProfilesRepository {
  final Dio _dio = ApiService.instance.dio;

  /// 获取所有配置档案
  Future<ProfileListResponse> listProfiles() async {
    try {
      final response = await _dio.get('/v1/account/profiles');
      return ProfileListResponse.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'items': response.data},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取单个配置档案
  Future<AIBackendProfile> getProfile(String id) async {
    try {
      final response = await _dio.get('/v1/account/profiles/$id');
      return AIBackendProfile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建新配置档案
  Future<AIBackendProfile> createProfile(ProfileRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/account/profiles',
        data: request.toJson(),
      );
      return AIBackendProfile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新配置档案
  Future<AIBackendProfile> updateProfile(String id, ProfileRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/account/profiles/$id',
        data: request.toJson(),
      );
      return AIBackendProfile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除配置档案
  Future<void> deleteProfile(String id) async {
    try {
      await _dio.delete('/v1/account/profiles/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 设置默认配置档案
  Future<void> setDefaultProfile(String id) async {
    try {
      await _dio.post('/v1/account/profiles/default', data: {'id': id});
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final dioError = error as DioException;
      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout) {
        return Exception('连接超时，请检查网络连接');
      }
      if (dioError.type == DioExceptionType.connectionError) {
        return Exception('网络连接失败，请检查网络设置');
      }
      if (dioError.type == DioExceptionType.badResponse) {
        final statusCode = dioError.response?.statusCode ?? '未知';
        return Exception('服务器错误($statusCode): ${dioError.message}');
      }
    }
    return Exception('请求失败: $error');
  }
}

/// Profiles State Provider
///
/// 管理 AI 配置档案状态
class ProfilesNotifier extends StateNotifier<ProfilesState> {
  final ProfilesRepository _repository;

  ProfilesNotifier(this._repository) : super(const ProfilesState.initial());

  /// 加载配置档案列表
  Future<void> loadProfiles() async {
    state = const ProfilesState.loading();
    try {
      final response = await _repository.listProfiles();
      state = ProfilesState.loaded(profiles: response.items);
    } catch (e) {
      state = ProfilesState.error(e.toString());
    }
  }

  /// 创建新配置档案
  Future<void> createProfile(ProfileRequest request) async {
    state = const ProfilesState.loading();
    try {
      final profile = await _repository.createProfile(request);
      final currentProfiles = state.maybeWhen(
        loaded: (value) => value.profiles,
        orElse: () => <AIBackendProfile>[],
      );
      state = ProfilesState.loaded(profiles: [...currentProfiles, profile]);
    } catch (e) {
      state = ProfilesState.error(e.toString());
    }
  }

  /// 更新配置档案
  Future<void> updateProfile(String id, ProfileRequest request) async {
    try {
      final profile = await _repository.updateProfile(id, request);
      final currentProfiles = state.maybeWhen(
        loaded: (value) => value.profiles.map((p) {
          if (p.id == id) return profile;
          return p;
        }),
        orElse: () => <AIBackendProfile>[],
      );
      state = ProfilesState.loaded(profiles: currentProfiles);
    } catch (e) {
      state = ProfilesState.error(e.toString());
    }
  }

  /// 删除配置档案
  Future<void> deleteProfile(String id) async {
    try {
      await _repository.deleteProfile(id);
      final currentProfiles = state.maybeWhen(
        loaded: (value) => value.profiles.where((p) => p.id != id).toList(),
        orElse: () => <AIBackendProfile>[],
      );
      state = ProfilesState.loaded(profiles: currentProfiles);
    } catch (e) {
      state = ProfilesState.error(e.toString());
    }
  }

  /// 设置默认档案
  Future<void> setDefaultProfile(String id) async {
    try {
      await _repository.setDefaultProfile(id);
      // 更新本地存储
      final updatedProfiles = state.maybeWhen(
        loaded: (value) => value.profiles.map((p) {
          p.isDefault = (p.id == id);
          return p;
        }),
        orElse: () => <AIBackendProfile>[],
      );
      state = ProfilesState.loaded(profiles: updatedProfiles);
    } catch (e) {
      state = ProfilesState.error(e.toString());
    }
  }

  /// 获取默认档案
  AIBackendProfile? get defaultProfile =>
      state.maybeWhen(
        loaded: (value) => value.profiles.firstWhere(
          (p) => p.isDefault == true,
          orElse: () => value.profiles.first,
        ),
        orElse: () => null,
      );

  /// 检查档案是否为默认
  bool isDefault(String id) =>
      state.maybeWhen(
        loaded: (value) => value.profiles.any((p) => p.id == id && p.isDefault),
        orElse: () => false,
      );
}

/// Profiles State
///
/// AI 配置档案状态枚举
class ProfilesState {
  final List<AIBackendProfile> profiles;
  final String? error;

  const ProfilesState({
    this.profiles = const [],
    this.error,
  });

  const ProfilesState.initial() : profiles = const [], error = null;

  const ProfilesState.loading() : profiles = const [], error = null;

  const ProfilesState.loaded({required this.profiles, this.error = null});

  const ProfilesState.error(this.error) : profiles = const [], error = error;

  bool get isLoading => profiles.isEmpty && error == null;

  bool get hasError => error != null;

  bool get isLoaded => profiles.isNotEmpty && error == null;

  T? when<T>({
    T Function() initial,
    required T Function(List<AIBackendProfile>, String?) loaded,
    required T Function(String) error,
  }) {
    if (hasError) {
      return error(error!);
    }
    if (isLoaded) {
      return loaded(profiles, null);
    }
    return initial();
  }

  T? maybeWhen<T>({
    T Function()? initial,
    T Function(List<AIBackendProfile>, String?)? loaded,
    T Function(String)? error,
  }) {
    if (hasError && error != null) {
      return error?.call();
    }
    if (isLoaded && loaded != null) {
      return loaded.call();
    }
    return initial?.call();
  }
}
