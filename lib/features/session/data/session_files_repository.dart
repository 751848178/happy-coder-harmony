import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/api_service.dart';
import '../domain/session_files_models.dart';

part 'session_files_notifier.dart';
part 'session_files_state.dart';

class SessionFilesApiException implements Exception {
  const SessionFilesApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Session Files Repository
///
/// 处理会话文件的所有数据操作
class SessionFilesRepository {
  final Dio _dio = ApiService.instance.dio;

  /// 获取会话文件列表
  Future<SessionFilesResponse> listFiles(
    String sessionId, {
    int limit = 100,
    String? cursor,
    String? fileType,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/sessions/$sessionId/files',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (fileType != null) 'type': fileType,
        },
      );
      return SessionFilesResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 上传文件到会话
  Future<SessionFile> uploadFile(UploadFileRequest request) async {
    try {
      final formData = FormData.fromMap({
        if (request.localPath != null)
          'file': await MultipartFile.fromFile(request.localPath!),
        if (request.base64Data != null) 'data': request.base64Data!,
      });

      final response = await _dio.post(
        '/v1/sessions/${request.sessionId}/files',
        data: formData,
      );
      return SessionFile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 读取文件内容
  Future<String> readFileContent(String fileId) async {
    try {
      final response = await _dio.get('/v1/sessions/files/$fileId/content');
      return response.data['content'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 按路径查找会话文件，兼容上游 `/session/:id/file?path=...` 流程。
  Future<SessionFile?> findFileByPath(String sessionId, String filePath) async {
    String? cursor;
    do {
      final response = await listFiles(
        sessionId,
        limit: 100,
        cursor: cursor,
      );

      for (final file in response.items) {
        if (file.filePath == filePath || file.fileName == filePath) {
          return file;
        }
      }

      cursor = response.nextCursor;
    } while (cursor != null && cursor.isNotEmpty);

    return null;
  }

  /// 删除文件
  Future<void> deleteFile(String sessionId, String fileId) async {
    try {
      await _dio.delete('/v1/sessions/$sessionId/files/$fileId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 监控文件操作历史
  Future<List<FileOperation>> getFileOperations({
    required String sessionId,
    int? sinceSeq,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/sessions/$sessionId/files/operations',
        queryParameters: {
          'limit': limit,
          if (sinceSeq != null) 'since': sinceSeq,
        },
      );

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};

      return (responseData['operations'] as List<dynamic>?)
              ?.map((op) => FileOperation.fromJson(op as Map<String, dynamic>))
              .toList() ??
          [];
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
        return const SessionFilesApiException(message: '连接超时，请检查网络连接');
      }
      if (dioError.type == DioExceptionType.connectionError) {
        return const SessionFilesApiException(message: '网络连接失败，请检查网络设置');
      }
      if (dioError.type == DioExceptionType.badResponse) {
        final statusCode = dioError.response?.statusCode ?? '未知';
        return SessionFilesApiException(
          message: '服务器错误($statusCode): ${dioError.message}',
          statusCode: dioError.response?.statusCode,
        );
      }
    }
    return SessionFilesApiException(message: '请求失败: $error');
  }
}
