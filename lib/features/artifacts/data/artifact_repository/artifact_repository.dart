import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/api_service.dart';
import '../../domain/artifact_models.dart';

part 'notifier.dart';
part 'state.dart';

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
  Future<Artifact> updateArtifact(
    String id,
    UpdateArtifactRequest request,
  ) async {
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
