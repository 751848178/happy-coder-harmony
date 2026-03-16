import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/data/token_storage_service.dart';

/// API 服务
///
/// 统一处理所有后端 API 调用，并自动注入已保存的认证 token。
class ApiService {
  ApiService._();

  static ApiService? _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.socketTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final TokenStorageService _tokenStorage = TokenStorageService.instance;
  bool _interceptorsBound = false;

  /// 获取单例
  static ApiService get instance => _instance ??= ApiService._();

  /// 获取 Dio 实例（用于特殊场景）
  Dio get dio {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    if (!_interceptorsBound) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final hasAuthorization = options.headers.keys.any(
              (key) => key.toString().toLowerCase() == 'authorization',
            );
            if (!hasAuthorization) {
              final token = await _tokenStorage.getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
            handler.next(options);
          },
        ),
      );
      _interceptorsBound = true;
    }
    return _dio;
  }

  /// 发送 GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送 POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送 PUT 请求
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送 DELETE 请求
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理响应
  T _handleResponse<T>(Response response) {
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      if (response.data is T) {
        return response.data as T;
      }
      throw Exception('Invalid response data type for $T');
    }
    throw Exception(
      'API request failed: ${response.statusCode} - ${response.statusMessage}',
    );
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final dioError = error;
      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout) {
        throw Exception('连接超时，请检查网络连接');
      }
      if (dioError.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败，请检查网络设置');
      }
      if (dioError.type == DioExceptionType.badResponse) {
        final statusCode = dioError.response?.statusCode ?? '未知';
        throw Exception('服务器错误($statusCode): ${dioError.message}');
      }
    }
    throw Exception('请求失败: $error');
  }
}
