import 'dart:math' as math;

import '../../domain/reducer.dart';
import '../../domain/session_files_models.dart';
import '../../domain/session_git_models.dart';
import '../../domain/session_models.dart';
import '../derived_session_files_service.dart';
import '../session_files_repository.dart';

part 'branch.dart';
part 'changes.dart';
part 'diff_utils.dart';
part 'models.dart';
part 'structured.dart';
part 'values.dart';

class SessionGitRepositoryService {
  SessionGitRepositoryService(
    this._filesRepository, {
    DerivedSessionFilesService? derivedFilesService,
  }) : _derivedFilesService =
            derivedFilesService ?? const DerivedSessionFilesService();

  final SessionFilesRepository _filesRepository;
  final DerivedSessionFilesService _derivedFilesService;

  Future<SessionGitRepositoryView> loadRepository(
    Session session, {
    required List<ReducerMessage> messages,
  }) async {
    final rootPath = _resolveRootPath(session);
    final files = await _loadAllFiles(session, messages);
    final fileIdsByPath = _buildFileIndex(files, rootPath: rootPath);
    final structured = _extractStructuredGitRepository(
      session,
      fileIdsByPath: fileIdsByPath,
    );

    final changes = <String, _MutableGitFile>{};
    if (structured != null) {
      for (final file in [
        ...structured.stagedFiles,
        ...structured.unstagedFiles
      ]) {
        _mergeChange(changes, _MutableGitFile.fromFile(file, priority: 3));
      }
    }

    final operations = await _loadOperations(session.id);
    for (final operation in operations) {
      final parsed = _parseFileOperation(
        operation,
        fileIdsByPath: fileIdsByPath,
      );
      if (parsed != null) {
        _mergeChange(changes, parsed);
      }
    }

    for (final message in messages) {
      final parsed = _parseToolChange(message, fileIdsByPath: fileIdsByPath);
      if (parsed != null) {
        _mergeChange(changes, parsed);
      }
    }

    final allChangedFiles = changes.values
        .map((change) => change.toFile())
        .toList()
      ..sort(_compareFiles);
    final stagedFiles = allChangedFiles.where((file) => file.isStaged).toList();
    final unstagedFiles =
        allChangedFiles.where((file) => !file.isStaged).toList();

    return SessionGitRepositoryView(
      rootPath: rootPath,
      branch: structured?.branch ?? _resolveBranch(session) ?? '当前工作区',
      stagedFiles: stagedFiles,
      unstagedFiles: unstagedFiles,
      totalTrackedFiles: files.isEmpty ? allChangedFiles.length : files.length,
      totalAddedLines: structured?.totalAddedLines ??
          allChangedFiles.fold<int>(0, (sum, file) => sum + file.addedLines),
      totalRemovedLines: structured?.totalRemovedLines ??
          allChangedFiles.fold<int>(0, (sum, file) => sum + file.removedLines),
      fromDerivedData: structured == null,
      sourceLabel: structured == null ? '基于当前会话文件操作与工具改动推断' : '来自会话元数据',
      lastUpdatedAt: _latestUpdatedAt(allChangedFiles),
    );
  }

  Future<List<SessionFile>> _loadAllFiles(
    Session session,
    List<ReducerMessage> messages,
  ) async {
    final files = <SessionFile>[];
    String? cursor;
    try {
      do {
        final response = await _filesRepository.listFiles(
          session.id,
          limit: 100,
          cursor: cursor,
        );
        files.addAll(response.items);
        cursor = response.nextCursor;
      } while (cursor != null && cursor.isNotEmpty);
      return files;
    } catch (_) {
      if (files.isNotEmpty) {
        return files;
      }
      return _derivedFilesService.deriveFiles(
        sessionId: session.id,
        session: session,
        messages: messages,
      );
    }
  }

  Future<List<FileOperation>> _loadOperations(String sessionId) async {
    try {
      final operations = await _filesRepository.getFileOperations(
        sessionId: sessionId,
        limit: 200,
      );
      operations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return operations;
    } catch (_) {
      return const [];
    }
  }
}
