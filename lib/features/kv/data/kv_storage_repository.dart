import 'package:dio/dio.dart';

import '../../../app/services/api_service.dart';
import '../domain/kv_models.dart';

class KVStorageRepository {
  KVStorageRepository({Dio? dio}) : _dio = dio ?? ApiService.instance.dio;

  final Dio _dio;

  Future<KVItem> getKV(String key) async {
    try {
      final response = await _dio.get('/v1/kv/$key');
      return KVItem.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<List<KVItem>> listKV({
    String? prefix,
    int limit = 100,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/kv',
        queryParameters: {
          if (prefix != null && prefix.isNotEmpty) 'prefix': prefix,
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );

      final responseData = response.data;
      final payload = responseData is Map<String, dynamic>
          ? responseData
          : <String, dynamic>{'items': responseData};
      return KVListResponse.fromJson(payload).items;
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<void> batchUpdateKV(KVBatchUpdateRequest request) async {
    try {
      await _dio.post(
        '/v1/kv',
        data: request.toJson(),
      );
    } catch (error) {
      throw _handleError(error);
    }
  }

  Future<void> setKV(String key, String value, {int? version}) {
    return batchUpdateKV(
      KVBatchUpdateRequest(
        mutations: [
          KVMutation(key: key, value: value, version: version),
        ],
      ),
    );
  }

  Future<void> deleteKV(String key) {
    return batchUpdateKV(
      KVBatchUpdateRequest(
        mutations: [
          KVMutation(key: key),
        ],
      ),
    );
  }

  Exception _handleError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Exception('连接超时，请检查网络连接');
      }
      if (error.type == DioExceptionType.connectionError) {
        return Exception('网络连接失败，请检查网络设置');
      }
      if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode ?? '未知';
        return Exception('服务器错误($statusCode): ${error.message}');
      }
    }

    return Exception('请求失败: $error');
  }
}
