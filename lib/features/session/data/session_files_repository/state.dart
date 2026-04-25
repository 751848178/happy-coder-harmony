part of 'session_files_repository.dart';

/// Session Files State
///
/// 会话文件状态枚举
class SessionFilesState {
  final List<SessionFile> files;
  final String? nextCursor;
  final int? totalCount;
  final SessionFile? currentFile;
  final String? fileContent;
  final List<FileOperation> operations;
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
