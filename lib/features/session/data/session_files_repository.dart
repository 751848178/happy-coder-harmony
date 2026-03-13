import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/services/api_service.dart';
import '../domain/session_files_models.dart';

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
          'file': await MultipartFile.fromFile(
            request.localPath!,
          ),
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

      final operations = (responseData['operations'] as List<dynamic>?)
              ?.map((op) => FileOperation.fromJson(op as Map<String, dynamic>))
              .toList() ??
          [];

      return operations;
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

/// Session Files State Provider
///
/// 管理会话文件状态和缓存
class SessionFilesNotifier extends StateNotifier<SessionFilesState> {
  final SessionFilesRepository _repository;
  final Map<String, SessionFile> _cache = {};

  SessionFilesNotifier(this._repository)
      : super(const SessionFilesState.initial());

  /// 刷新文件列表
  Future<void> loadFiles({
    required String sessionId,
    int limit = 100,
    String? cursor,
    String? fileType,
  }) async {
    state = const SessionFilesState.loading();
    try {
      final response = await _repository.listFiles(
        sessionId,
        limit: limit,
        cursor: cursor,
        fileType: fileType,
      );

      // 更新缓存
      for (final file in response.items) {
        _cache[file.id] = file;
      }

      state = SessionFilesState.loaded(
        files: response.items,
        nextCursor: response.nextCursor,
        totalCount: response.totalCount,
      );
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }

  /// 加载单个文件详情
  Future<void> loadFileDetail(String fileId) async {
    // 先检查缓存
    if (_cache.containsKey(fileId)) {
      state = SessionFilesState.fileLoaded(
        currentFile: _cache[fileId]!,
      );
      return;
    }

    try {
      // 加载文件内容
      final content = await _repository.readFileContent(fileId);
      final file = _cache[fileId]!;
      _cache[fileId] = file;

      state = SessionFilesState.fileLoaded(
        currentFile: file,
        fileContent: content,
      );
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }

  /// 上传文件
  Future<void> uploadFile(UploadFileRequest request) async {
    state = const SessionFilesState.loading();
    try {
      final file = await _repository.uploadFile(request);

      // 更新缓存
      _cache[file.id] = file;

      // 重新加载列表
      await loadFiles(sessionId: request.sessionId);
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }

  /// 删除文件
  Future<void> deleteFile(String sessionId, String fileId) async {
    state = const SessionFilesState.loading();
    try {
      await _repository.deleteFile(sessionId, fileId);

      // 从缓存移除
      _cache.remove(fileId);

      // 重新加载列表
      await loadFiles(sessionId: sessionId);
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }

  /// 刷新操作历史
  Future<void> refreshOperations(String sessionId,
      {int? sinceSeq, int limit = 50}) async {
    try {
      final operations = await _repository.getFileOperations(
        sessionId: sessionId,
        sinceSeq: sinceSeq,
        limit: limit,
      );

      state = SessionFilesState.loaded(
        files: state.files,
        nextCursor: state.nextCursor,
        totalCount: state.totalCount,
        operations: operations,
      );
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }
}

/// Session Files State
///
/// 会话文件状态枚举
class SessionFilesState {
  final List<SessionFile> files;
  final String? nextCursor;
  final int? totalCount;
  final SessionFile? currentFile; // 当前查看的文件
  final String? fileContent; // 当前文件内容
  final List<FileOperation> operations; // 文件操作历史
  final String? error;

  const SessionFilesState.initial()
      : files = const [],
        nextCursor = null,
        totalCount = null,
        currentFile = null,
        fileContent = null,
        operations = const [],
        error = null;

  const SessionFilesState.loading()
      : files = const [],
        nextCursor = null,
        totalCount = null,
        currentFile = null,
        fileContent = null,
        operations = const [],
        error = null;

  const SessionFilesState.loaded({
    required this.files,
    this.nextCursor,
    this.totalCount,
    this.operations = const [],
    this.currentFile,
    this.fileContent,
  }) : error = null;

  const SessionFilesState.fileLoaded({
    required this.currentFile,
    this.fileContent,
  })  : files = const [],
        nextCursor = null,
        totalCount = null,
        operations = const [],
        error = null;

  const SessionFilesState.error(this.error)
      : files = const [],
        nextCursor = null,
        totalCount = null,
        currentFile = null,
        fileContent = null,
        operations = const [];

  bool get isLoading => files.isEmpty && error == null;

  bool get hasError => error != null;

  T? when<T>({
    T Function()? initial,
    required T Function(List<SessionFile>, String?, int?) loaded,
    required T Function(String) error,
  }) {
    if (hasError) {
      return error(this.error!);
    }
    if (isLoading) {
      return initial?.call();
    }
    return loaded(files, nextCursor, totalCount);
  }

  T? maybeWhen<T>({
    T Function()? initial,
    T Function(List<SessionFile>, String?, int?)? loaded,
    T Function(String)? error,
  }) {
    if (hasError && error != null) {
      return error.call(this.error!);
    }
    if (!isLoading && loaded != null) {
      return loaded.call(files, nextCursor, totalCount);
    }
    return initial?.call();
  }
}
