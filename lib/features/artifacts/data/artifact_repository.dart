import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/api_service.dart';
import '../domain/artifact_models.dart';

/// Artifact Repository
///
/// 处理工件的所有数据操作
class ArtifactRepository {
  final Dio _dio = ApiService.instance.dio;

  /// 获取所有工件列表
  Future<ArtifactListResponse> listArtifacts({
    int limit = 100,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/artifacts',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );

      return ArtifactListResponse.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'items': response.data, 'nextCursor': null},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取单个工件
  Future<Artifact> getArtifact(String id) async {
    try {
      final response = await _dio.get('/v1/artifacts/$id');
      return Artifact.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建新工件
  Future<Artifact> createArtifact(CreateArtifactRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/artifacts',
        data: request.toJson(),
      );
      return Artifact.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新工件
  Future<Artifact> updateArtifact(String id, UpdateArtifactRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/artifacts/$id',
        data: request.toJson(),
      );
      return Artifact.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新工件头部
  Future<Artifact> updateArtifactHeader(
    String id,
    String header,
    int? headerVersion,
  ) async {
    return updateArtifact(
      id,
      UpdateArtifactRequest(
        header: header,
        headerVersion: headerVersion,
      ),
    );
  }

  /// 更新工件主体
  Future<Artifact> updateArtifactBody(
    String id,
    String body,
    int? bodyVersion,
  ) async {
    return updateArtifact(
      id,
      UpdateArtifactRequest(
        body: body,
        bodyVersion: bodyVersion,
      ),
    );
  }

  /// 删除工件
  Future<void> deleteArtifact(String id) async {
    try {
      await _dio.delete('/v1/artifacts/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final dioError = error;
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

/// Artifact State Provider
///
/// 管理工件状态和列表
class ArtifactNotifier extends StateNotifier<ArtifactState> {
  final ArtifactRepository _repository;

  ArtifactNotifier(this._repository) : super(const ArtifactState.initial());

  /// 加载工件列表
  Future<void> loadArtifacts({String? cursor, int limit = 100}) async {
    state = const ArtifactState.loading();
    try {
      final response = await _repository.listArtifacts(
        limit: limit,
        cursor: cursor,
      );
      state = ArtifactState.loaded(
        artifacts: response.items,
        nextCursor: response.nextCursor,
      );
    } catch (e) {
      state = ArtifactState.error(e.toString());
    }
  }

  /// 加载单个工件
  Future<Artifact?> loadArtifact(String id) async {
    try {
      final artifact = await _repository.getArtifact(id);
      final currentArtifacts = [...state.artifacts];
      final index = currentArtifacts.indexWhere((item) => item.id == id);
      if (index == -1) {
        currentArtifacts.insert(0, artifact);
      } else {
        currentArtifacts[index] = artifact;
      }
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.nextCursor,
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 创建工件
  Future<Artifact?> createArtifact(CreateArtifactRequest request) async {
    final previousArtifacts = [...state.artifacts];
    final previousCursor = state.nextCursor;
    try {
      final artifact = await _repository.createArtifact(request);
      state = ArtifactState.loaded(
        artifacts: [
          artifact,
          ...previousArtifacts.where((item) => item.id != artifact.id),
        ],
        nextCursor: previousCursor,
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 更新工件
  Future<Artifact?> updateArtifact(String id, UpdateArtifactRequest request) async {
    try {
      final artifact = await _repository.updateArtifact(id, request);
      final currentArtifacts = [...state.artifacts];
      final index = currentArtifacts.indexWhere((item) => item.id == id);
      if (index == -1) {
        currentArtifacts.insert(0, artifact);
      } else {
        currentArtifacts[index] = artifact;
      }
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.maybeWhen<String?>(
          loaded: (_, nextCursor) => nextCursor,
          orElse: () => null,
        ),
      );
      return artifact;
    } catch (e) {
      state = ArtifactState.error(e.toString());
      return null;
    }
  }

  /// 删除工件
  Future<void> deleteArtifact(String id) async {
    try {
      await _repository.deleteArtifact(id);
      final currentArtifacts = state.maybeWhen(
        loaded: (artifacts, _) => artifacts.where((a) => a.id != id).toList(),
        orElse: () => <Artifact>[],
      ) ?? <Artifact>[];
      state = ArtifactState.loaded(
        artifacts: currentArtifacts,
        nextCursor: state.maybeWhen<String?>(
          loaded: (_, nextCursor) => nextCursor,
          orElse: () => null,
        ),
      );
    } catch (e) {
      state = ArtifactState.error(e.toString());
    }
  }
}

/// Artifact State
///
/// 工件状态枚举
class ArtifactState {
  final List<Artifact> artifacts;
  final String? nextCursor;
  final String? error;

  const ArtifactState({
    this.artifacts = const [],
    this.nextCursor,
    this.error,
  });

  const ArtifactState.initial()
      : artifacts = const [],
        nextCursor = null,
        error = null;

  const ArtifactState.loading()
      : artifacts = const [],
        nextCursor = null,
        error = null;

  const ArtifactState.loaded({
    required this.artifacts,
    this.nextCursor,
    this.error = null,
  });

  const ArtifactState.error(String errorMessage)
      : artifacts = const [],
        nextCursor = null,
        error = errorMessage;

  bool get isLoading => artifacts.isEmpty && error == null && nextCursor == null;

  bool get hasError => error != null;

  bool get isLoaded => artifacts.isNotEmpty && error == null;

  T? when<T>({
    T Function()? initial,
    required T Function(List<Artifact>, String?) loaded,
    required T Function(String) error,
  }) {
    if (hasError) {
      return error(this.error!);
    }
    if (isLoaded) {
      return loaded(artifacts, nextCursor);
    }
    return initial?.call();
  }

  T? maybeWhen<T>({
    T Function()? orElse,
    T Function(List<Artifact>, String?)? loaded,
    T Function(String)? error,
  }) {
    if (hasError && error != null) {
      return error.call(this.error!);
    }
    if (isLoaded && loaded != null) {
      return loaded.call(artifacts, nextCursor);
    }
    return orElse?.call();
  }
}
