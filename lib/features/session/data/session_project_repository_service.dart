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

class SessionProjectRepositoryData {
  const SessionProjectRepositoryData({
    required this.repository,
    required this.projectFiles,
    required this.usedRpc,
  });

  final SessionGitRepositoryView repository;
  final List<SessionFile> projectFiles;
  final bool usedRpc;
}

class SessionProjectFileContent {
  const SessionProjectFileContent({
    required this.content,
    required this.isBinary,
    required this.sourceLabel,
  });

  final String content;
  final bool isBinary;
  final String sourceLabel;
}

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

    if (repositoryView == null) {
      repositoryView = await _fallbackGitRepository.loadRepository(
        session,
        messages: messages,
      );
    }

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

  Future<List<SessionFile>> _loadProjectFiles({
    required Session session,
    required SessionServiceNotifier notifier,
    required List<SessionGitFile> changedFiles,
  }) async {
    final rootPath = session.path;
    if (rootPath == null || rootPath.trim().isEmpty) {
      return const [];
    }

    String stdout = '';
    final ripgrepResponse = await notifier.executeSessionRipgrep(
      sessionId: session.id,
      args: const ['--files', '--follow'],
      cwd: rootPath,
    );
    if (ripgrepResponse.success && ripgrepResponse.stdout.trim().isNotEmpty) {
      stdout = ripgrepResponse.stdout;
    }

    if (stdout.trim().isEmpty) {
      final bashResponse = await notifier.executeSessionBash(
        sessionId: session.id,
        command: 'rg --files --follow',
        cwd: rootPath,
        timeout: 10000,
      );
      if (bashResponse.success && bashResponse.stdout.trim().isNotEmpty) {
        stdout = bashResponse.stdout;
      }
    }

    if (stdout.trim().isEmpty) {
      final bashResponse = await notifier.executeSessionBash(
        sessionId: session.id,
        command: 'find . -type f | sed \'s#^./##\'',
        cwd: rootPath,
        timeout: 10000,
      );
      if (bashResponse.success && bashResponse.stdout.trim().isNotEmpty) {
        stdout = bashResponse.stdout;
      }
    }

    final paths = stdout
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final changedByPath = <String, SessionGitFile>{
      for (final file in changedFiles) file.path: file,
    };

    for (final file in changedFiles) {
      if (!paths.contains(file.path) &&
          file.status != SessionGitFileStatus.deleted) {
        paths.add(file.path);
      }
    }

    final createdAt = session.createdAt.millisecondsSinceEpoch;
    final updatedAt = session.updatedAt.millisecondsSinceEpoch;
    return paths.map((path) {
      final changed = changedByPath[path];
      return SessionFile(
        id: 'repo:${base64Url.encode(utf8.encode(path))}',
        sessionId: session.id,
        filePath: path,
        fileName: path.split('/').last,
        mimeType: _guessMimeType(path),
        size: null,
        createdAt: createdAt,
        updatedAt: changed?.updatedAt?.millisecondsSinceEpoch ?? updatedAt,
      );
    }).toList();
  }

  Future<_GitStatusFilesData?> _loadGitStatusFiles({
    required Session session,
    required SessionServiceNotifier notifier,
  }) async {
    final rootPath = session.path;
    if (rootPath == null || rootPath.trim().isEmpty) {
      return null;
    }

    final statusResult = await notifier.executeSessionBash(
      sessionId: session.id,
      command: 'git status --porcelain=v2 --branch --untracked-files=all',
      cwd: rootPath,
      timeout: 10000,
    );

    if (!statusResult.success ||
        statusResult.exitCode != 0 ||
        statusResult.stdout.trim().isEmpty) {
      return null;
    }

    final diffResult = await notifier.executeSessionBash(
      sessionId: session.id,
      command:
          'git diff --numstat HEAD && echo "---STAGED---" && git diff --cached --numstat',
      cwd: rootPath,
      timeout: 10000,
    );

    final diffOutput = diffResult.success ? diffResult.stdout : '';
    return _parseGitStatusFilesV2(
      sessionId: session.id,
      statusOutput: statusResult.stdout,
      combinedDiffOutput: diffOutput,
    );
  }

  _GitStatusFilesData _parseGitStatusFilesV2({
    required String sessionId,
    required String statusOutput,
    required String combinedDiffOutput,
  }) {
    final summary = _parseStatusSummaryV2(statusOutput);
    final parts = combinedDiffOutput.split('---STAGED---');
    final unstagedStats = _createDiffStatsMap(
      _parseNumStat(parts.isNotEmpty ? parts.first.trim() : ''),
    );
    final stagedStats = _createDiffStatsMap(
      _parseNumStat(parts.length > 1 ? parts[1].trim() : ''),
    );

    final stagedFiles = <SessionGitFile>[];
    final unstagedFiles = <SessionGitFile>[];

    for (final file in summary.files) {
      if (file.index != ' ' && file.index != '.' && file.index != '?') {
        final stats = stagedStats[file.path] ?? const _DiffNumbers();
        stagedFiles.add(
          SessionGitFile(
            path: file.path,
            fileName: _basename(file.path),
            status: _statusFromCode(file.index),
            previousPath: file.from,
            isStaged: true,
            addedLines: stats.added,
            removedLines: stats.removed,
          ),
        );
      }

      if (file.workingDir != ' ' && file.workingDir != '.') {
        final stats = unstagedStats[file.path] ?? const _DiffNumbers();
        unstagedFiles.add(
          SessionGitFile(
            path: file.path,
            fileName: _basename(file.path),
            status: _statusFromCode(file.workingDir),
            previousPath: file.from,
            isStaged: false,
            addedLines: stats.added,
            removedLines: stats.removed,
          ),
        );
      }
    }

    for (final untrackedPath in summary.untracked) {
      unstagedFiles.add(
        SessionGitFile(
          path: untrackedPath,
          fileName: _basename(untrackedPath),
          status: SessionGitFileStatus.untracked,
          isStaged: false,
        ),
      );
    }

    return _GitStatusFilesData(
      stagedFiles: stagedFiles,
      unstagedFiles: unstagedFiles,
      branch: summary.branchHead == '(detached)' ? null : summary.branchHead,
      totalStaged: stagedFiles.length,
      totalUnstaged: unstagedFiles.length,
    );
  }

  _GitStatusSummaryV2 _parseStatusSummaryV2(String output) {
    final summary = _GitStatusSummaryV2();
    final lines = output
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty);

    final ordinaryPattern = RegExp(
      r'^1 (.)(.) (.{4}) (\d{6}) (\d{6}) (\d{6}) ([0-9a-f]+) ([0-9a-f]+) (.+)$',
    );
    final renamePattern = RegExp(
      r'^2 (.)(.) (.{4}) (\d{6}) (\d{6}) (\d{6}) ([0-9a-f]+) ([0-9a-f]+) ([RC])(\d{1,3}) (.+)\t(.+)$',
    );
    final untrackedPattern = RegExp(r'^\? (.+)$');

    for (final line in lines) {
      if (line.startsWith('# branch.head ')) {
        summary.branchHead = line.substring('# branch.head '.length).trim();
        continue;
      }

      final ordinary = ordinaryPattern.firstMatch(line);
      if (ordinary != null) {
        summary.files.add(
          _GitStatusEntry(
            path: ordinary.group(9)!.trim(),
            index: ordinary.group(1)!,
            workingDir: ordinary.group(2)!,
          ),
        );
        continue;
      }

      final renamed = renamePattern.firstMatch(line);
      if (renamed != null) {
        summary.files.add(
          _GitStatusEntry(
            path: renamed.group(12)!.trim(),
            index: renamed.group(1)!,
            workingDir: renamed.group(2)!,
            from: renamed.group(11)?.trim(),
          ),
        );
        continue;
      }

      final untracked = untrackedPattern.firstMatch(line);
      if (untracked != null) {
        final path = untracked.group(1)!.trim();
        if (!path.endsWith('/')) {
          summary.untracked.add(path);
        }
      }
    }

    return summary;
  }

  _DiffSummary _parseNumStat(String output) {
    final summary = _DiffSummary();
    final pattern = RegExp(r'^(\d+|-)\t(\d+|-)\t(.*)$');

    for (final line in output.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        continue;
      }
      final match = pattern.firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final insertionsRaw = match.group(1)!;
      final deletionsRaw = match.group(2)!;
      final file = match.group(3)!.trim();
      if (file.isEmpty) {
        continue;
      }

      final isBinary = insertionsRaw == '-' || deletionsRaw == '-';
      summary.files.add(
        _DiffFileStat(
          file: file,
          added: isBinary ? 0 : int.tryParse(insertionsRaw) ?? 0,
          removed: isBinary ? 0 : int.tryParse(deletionsRaw) ?? 0,
        ),
      );
    }

    return summary;
  }

  Map<String, _DiffNumbers> _createDiffStatsMap(_DiffSummary summary) {
    return {
      for (final file in summary.files)
        file.file: _DiffNumbers(
          added: file.added,
          removed: file.removed,
        ),
    };
  }

  SessionGitFileStatus _statusFromCode(String code) {
    switch (code) {
      case 'A':
        return SessionGitFileStatus.added;
      case 'D':
        return SessionGitFileStatus.deleted;
      case 'R':
      case 'C':
        return SessionGitFileStatus.renamed;
      case '?':
        return SessionGitFileStatus.untracked;
      default:
        return SessionGitFileStatus.modified;
    }
  }

  String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }

  bool _looksBinary(String content) {
    if (content.isEmpty) {
      return false;
    }
    final hasNullBytes = content.contains('\u0000');
    if (hasNullBytes) {
      return true;
    }
    final nonPrintableCount = content.runes.where((code) {
      return code < 32 && code != 9 && code != 10 && code != 13;
    }).length;
    return nonPrintableCount / content.length > 0.1;
  }

  String _basename(String path) {
    final segments = path.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  String? _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
      return 'text/markdown';
    }
    if (lower.endsWith('.json')) {
      return 'application/json';
    }
    if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
      return 'application/yaml';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return null;
  }
}

class _GitStatusFilesData {
  const _GitStatusFilesData({
    required this.stagedFiles,
    required this.unstagedFiles,
    required this.branch,
    required this.totalStaged,
    required this.totalUnstaged,
  });

  final List<SessionGitFile> stagedFiles;
  final List<SessionGitFile> unstagedFiles;
  final String? branch;
  final int totalStaged;
  final int totalUnstaged;
}

class _GitStatusSummaryV2 {
  final List<_GitStatusEntry> files = <_GitStatusEntry>[];
  final List<String> untracked = <String>[];
  String? branchHead;
}

class _GitStatusEntry {
  const _GitStatusEntry({
    required this.path,
    required this.index,
    required this.workingDir,
    this.from,
  });

  final String path;
  final String index;
  final String workingDir;
  final String? from;
}

class _DiffSummary {
  final List<_DiffFileStat> files = <_DiffFileStat>[];
}

class _DiffFileStat {
  const _DiffFileStat({
    required this.file,
    required this.added,
    required this.removed,
  });

  final String file;
  final int added;
  final int removed;
}

class _DiffNumbers {
  const _DiffNumbers({
    this.added = 0,
    this.removed = 0,
  });

  final int added;
  final int removed;
}
