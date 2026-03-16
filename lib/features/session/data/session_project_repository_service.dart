import 'dart:convert';

import '../../encryption/domain/crypto_service.dart';
import '../domain/reducer.dart';
import '../domain/session_files_models.dart';
import '../domain/session_git_models.dart';
import '../domain/session_service.dart';
import '../domain/session_models.dart';
import 'derived_session_files_service.dart';
import 'session_files_repository.dart';
import 'session_git_repository.dart';

part 'session_project_repository_service_git_status.dart';
part 'session_project_repository_service_helpers.dart';
part 'session_project_repository_service_models.dart';
part 'session_project_repository_service_project_files.dart';

class SessionProjectRepositoryService {
  SessionProjectRepositoryService({
    SessionFilesRepository? filesRepository,
    DerivedSessionFilesService? derivedFilesService,
  })  : _derivedFilesService =
            derivedFilesService ?? const DerivedSessionFilesService(),
        _fallbackGitRepository = SessionGitRepositoryService(
          filesRepository ?? SessionFilesRepository(),
          derivedFilesService: derivedFilesService,
        );

  final DerivedSessionFilesService _derivedFilesService;
  final SessionGitRepositoryService _fallbackGitRepository;

  Future<SessionProjectRepositoryData> load({
    required Session session,
    required List<ReducerMessage> messages,
    required SessionServiceNotifier notifier,
  }) async {
    SessionGitRepositoryView? repositoryView;
    List<SessionFile> projectFiles = const [];
    var usedRpc = false;
    final gitStatusFiles = await _loadGitStatusFiles(
      session: session,
      notifier: notifier,
    );
    if (gitStatusFiles != null) {
      repositoryView = SessionGitRepositoryView(
        rootPath: session.path ?? '',
        branch: gitStatusFiles.branch ?? '当前工作区',
        stagedFiles: gitStatusFiles.stagedFiles,
        unstagedFiles: gitStatusFiles.unstagedFiles,
        totalTrackedFiles:
            gitStatusFiles.totalStaged + gitStatusFiles.totalUnstaged,
        totalAddedLines: [
          ...gitStatusFiles.stagedFiles,
          ...gitStatusFiles.unstagedFiles,
        ].fold<int>(0, (sum, file) => sum + file.addedLines),
        totalRemovedLines: [
          ...gitStatusFiles.stagedFiles,
          ...gitStatusFiles.unstagedFiles,
        ].fold<int>(0, (sum, file) => sum + file.removedLines),
        fromDerivedData: false,
        sourceLabel: '来自会话 RPC 的 Git 实时状态',
        lastUpdatedAt: DateTime.now(),
      );
      usedRpc = true;
    }
    projectFiles = await _loadProjectFiles(
      session: session,
      notifier: notifier,
      changedFiles: repositoryView?.changedFiles ?? const [],
    );
    repositoryView ??= await _fallbackGitRepository.loadRepository(session,
        messages: messages);
    if (projectFiles.isEmpty) {
      projectFiles = _derivedFilesService.deriveFiles(
        sessionId: session.id,
        session: session,
        messages: messages,
      );
    }
    if (projectFiles.isNotEmpty &&
        repositoryView.totalTrackedFiles != projectFiles.length) {
      repositoryView = repositoryView.copyWith(
        totalTrackedFiles: projectFiles.length,
      );
    }
    return SessionProjectRepositoryData(
      repository: repositoryView,
      projectFiles: projectFiles,
      usedRpc: usedRpc,
    );
  }

  Future<String?> loadGitDiff({
    required Session session,
    required SessionServiceNotifier notifier,
    required SessionGitFile file,
  }) async {
    if ((session.path ?? '').trim().isEmpty) {
      return file.diff;
    }
    final path = file.path.trim();
    if (path.isEmpty) {
      return file.diff;
    }
    final commands = <String>[
      'git diff --no-ext-diff -- ${_shellQuote(path)}',
      'git diff --cached --no-ext-diff -- ${_shellQuote(path)}',
    ];
    if (file.status == SessionGitFileStatus.untracked ||
        file.status == SessionGitFileStatus.added) {
      commands.add(
        'git diff --no-ext-diff --no-index -- /dev/null ${_shellQuote(path)}',
      );
    }
    for (final command in commands) {
      final response = await notifier.executeSessionBash(
        sessionId: session.id,
        command: command,
        cwd: session.path,
        timeout: 10000,
      );
      final output = response.stdout.trimRight();
      if (response.success && output.isNotEmpty) {
        return output;
      }
    }
    return file.diff;
  }

  Future<SessionProjectFileContent?> readFileContent({
    required Session session,
    required SessionServiceNotifier notifier,
    required String filePath,
  }) async {
    final trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      return null;
    }
    final readResponse = await notifier.readSessionFile(
      sessionId: session.id,
      path: trimmedPath,
    );
    if (!readResponse.success || readResponse.content == null) {
      return null;
    }
    final rawContent = readResponse.content!;
    final decoded = CryptoService.decodeBase64Flexible(rawContent);
    if (decoded.isEmpty && rawContent.trim().isNotEmpty) {
      return SessionProjectFileContent(
        content: rawContent,
        isBinary: _looksBinary(rawContent),
        sourceLabel: '来自会话 RPC 的文件内容',
      );
    }
    try {
      final content = utf8.decode(decoded);
      return SessionProjectFileContent(
        content: content,
        isBinary: _looksBinary(content),
        sourceLabel: '来自会话 RPC 的文件内容',
      );
    } catch (_) {
      return const SessionProjectFileContent(
        content: '',
        isBinary: true,
        sourceLabel: '来自会话 RPC 的文件内容',
      );
    }
  }
}
