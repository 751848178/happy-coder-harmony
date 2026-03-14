part of 'session_files_repository.dart';

/// Session Files State Provider
///
/// 管理会话文件状态和缓存
class SessionFilesNotifier extends StateNotifier<SessionFilesState> {
  SessionFilesNotifier(this._repository)
      : super(const SessionFilesState.initial());

  final SessionFilesRepository _repository;
  final Map<String, SessionFile> _cache = {};

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
    if (_cache.containsKey(fileId)) {
      state = SessionFilesState.fileLoaded(currentFile: _cache[fileId]!);
      return;
    }

    try {
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
      _cache[file.id] = file;
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
      _cache.remove(fileId);
      await loadFiles(sessionId: sessionId);
    } catch (e) {
      state = SessionFilesState.error(e.toString());
    }
  }

  /// 刷新操作历史
  Future<void> refreshOperations(
    String sessionId, {
    int? sinceSeq,
    int limit = 50,
  }) async {
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
