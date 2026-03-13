import 'dart:math' as math;

import '../domain/reducer.dart';
import '../domain/session_files_models.dart';
import '../domain/session_git_models.dart';
import '../domain/session_models.dart';
import 'derived_session_files_service.dart';
import 'session_files_repository.dart';

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
      final parsed = _parseToolChange(
        message,
        fileIdsByPath: fileIdsByPath,
      );
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

    final totalAddedLines = structured?.totalAddedLines ??
        allChangedFiles.fold<int>(0, (sum, file) => sum + file.addedLines);
    final totalRemovedLines = structured?.totalRemovedLines ??
        allChangedFiles.fold<int>(0, (sum, file) => sum + file.removedLines);

    return SessionGitRepositoryView(
      rootPath: rootPath,
      branch: structured?.branch ?? _resolveBranch(session) ?? '当前工作区',
      stagedFiles: stagedFiles,
      unstagedFiles: unstagedFiles,
      totalTrackedFiles: files.isEmpty ? allChangedFiles.length : files.length,
      totalAddedLines: totalAddedLines,
      totalRemovedLines: totalRemovedLines,
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

  _StructuredGitRepository? _extractStructuredGitRepository(
    Session session, {
    required Map<String, String> fileIdsByPath,
  }) {
    final candidates = <Map<String, dynamic>?>[
      _asMap(session.metadata?['git']),
      _asMap(session.metadata?['gitStatus']),
      _asMap(session.metadata?['repository']),
      _asMap(session.metadata?['repo']),
      _asMap(session.agentState?['git']),
      _asMap(session.agentState?['gitStatus']),
      _asMap(session.agentState?['repository']),
      _asMap(session.agentState?['repo']),
    ];

    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final stagedFiles = _parseStructuredFiles(
        candidate['stagedFiles'],
        isStaged: true,
        fileIdsByPath: fileIdsByPath,
      );
      final unstagedFiles = _parseStructuredFiles(
        candidate['unstagedFiles'] ?? candidate['files'],
        isStaged: false,
        fileIdsByPath: fileIdsByPath,
      );

      final branch = _firstNonEmpty([
        candidate['branch']?.toString(),
        candidate['branchName']?.toString(),
        candidate['currentBranch']?.toString(),
        candidate['gitBranch']?.toString(),
      ]);

      if (branch == null && stagedFiles.isEmpty && unstagedFiles.isEmpty) {
        continue;
      }

      return _StructuredGitRepository(
        branch: branch ?? '当前工作区',
        stagedFiles: stagedFiles,
        unstagedFiles: unstagedFiles,
        totalAddedLines: _firstPositive([
              _toInt(candidate['totalAddedLines']),
              _toInt(candidate['addedLines']),
              _toInt(candidate['insertions']),
            ]) ??
            [...stagedFiles, ...unstagedFiles]
                .fold<int>(0, (sum, file) => sum + file.addedLines),
        totalRemovedLines: _firstPositive([
              _toInt(candidate['totalRemovedLines']),
              _toInt(candidate['removedLines']),
              _toInt(candidate['deletions']),
            ]) ??
            [...stagedFiles, ...unstagedFiles]
                .fold<int>(0, (sum, file) => sum + file.removedLines),
      );
    }

    return null;
  }

  List<SessionGitFile> _parseStructuredFiles(
    dynamic rawFiles, {
    required bool isStaged,
    required Map<String, String> fileIdsByPath,
  }) {
    if (rawFiles is! List) {
      return const [];
    }
    final files = <SessionGitFile>[];
    for (final rawFile in rawFiles.whereType<Map>()) {
      final map = rawFile.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final rawPath = _firstNonEmpty([
        map['filePath']?.toString(),
        map['path']?.toString(),
        map['fullPath']?.toString(),
        map['fileName']?.toString(),
      ]);
      if (rawPath == null) {
        continue;
      }
      final normalizedPath = _normalizePath(rawPath);
      files.add(
        SessionGitFile(
          path: normalizedPath,
          fileName: _fileName(normalizedPath),
          fileId: _lookupFileId(fileIdsByPath, normalizedPath),
          previousPath: _firstNonEmpty([
            map['oldPath']?.toString(),
            map['previousPath']?.toString(),
          ]),
          status: _parseStatus(
            _firstNonEmpty([
              map['status']?.toString(),
              map['type']?.toString(),
            ]),
          ),
          isStaged: map['isStaged'] == true || isStaged,
          addedLines: _firstPositive([
                _toInt(map['linesAdded']),
                _toInt(map['addedLines']),
                _toInt(map['insertions']),
              ]) ??
              0,
          removedLines: _firstPositive([
                _toInt(map['linesRemoved']),
                _toInt(map['removedLines']),
                _toInt(map['deletions']),
              ]) ??
              0,
          diff: _firstNonEmpty([
            map['diff']?.toString(),
            map['patch']?.toString(),
          ]),
          updatedAt: _parseDateTime(
            map['updatedAt'] ?? map['lastUpdatedAt'] ?? map['timestamp'],
          ),
        ),
      );
    }
    return files;
  }

  _MutableGitFile? _parseFileOperation(
    FileOperation operation, {
    required Map<String, String> fileIdsByPath,
  }) {
    if (operation.operation == FileOperationType.read) {
      return null;
    }
    final rawPath = operation.filePath;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }
    final path = _normalizePath(rawPath);
    final diff = _buildUnifiedDiff(
      path: path,
      oldContent: operation.oldContent,
      newContent: operation.newContent,
    );
    final summary = _countDiffLines(diff);
    return _MutableGitFile(
      path: path,
      fileName: _fileName(path),
      status: switch (operation.operation) {
        FileOperationType.delete => SessionGitFileStatus.deleted,
        FileOperationType.write => operation.oldContent == null
            ? SessionGitFileStatus.added
            : SessionGitFileStatus.modified,
        FileOperationType.read => SessionGitFileStatus.modified,
      },
      fileId: _lookupFileId(fileIdsByPath, path),
      isStaged: false,
      addedLines: summary.$1,
      removedLines: summary.$2,
      diff: diff,
      updatedAt: operation.timestamp,
      priority: 2,
    );
  }

  _MutableGitFile? _parseToolChange(
    ReducerMessage message, {
    required Map<String, String> fileIdsByPath,
  }) {
    final tool = message.tool;
    if (tool == null) {
      return null;
    }
    final lowerTool = tool.name.toLowerCase();
    final isChangeTool = lowerTool.contains('edit') ||
        lowerTool.contains('write') ||
        lowerTool.contains('patch') ||
        lowerTool.contains('diff');
    if (!isChangeTool) {
      return null;
    }

    final diff = _extractDiff(tool);
    final path = _firstNonEmpty([
      _extractPrimaryPath(tool.arguments),
      if (diff != null) _extractPathFromDiff(diff),
    ]);
    if (path == null) {
      return null;
    }

    final normalizedPath = _normalizePath(path);
    final summary = _countDiffLines(diff);
    final oldText = _stringValue(tool.arguments['old_string']) ??
        _stringValue(tool.arguments['oldText']);
    final newText = _stringValue(tool.arguments['new_string']) ??
        _stringValue(tool.arguments['newText']);

    return _MutableGitFile(
      path: normalizedPath,
      fileName: _fileName(normalizedPath),
      fileId: _lookupFileId(fileIdsByPath, normalizedPath),
      previousPath: _firstNonEmpty([
        _stringValue(tool.arguments['old_path']),
        _stringValue(tool.arguments['source_path']),
      ]),
      status: _inferStatus(
        toolName: lowerTool,
        diff: diff,
        oldText: oldText,
        newText: newText,
      ),
      isStaged: false,
      addedLines: summary.$1,
      removedLines: summary.$2,
      diff: diff ??
          _buildUnifiedDiff(
            path: normalizedPath,
            oldContent: oldText,
            newContent: newText,
          ),
      updatedAt: message.createdAt,
      priority: 1,
    );
  }

  void _mergeChange(
    Map<String, _MutableGitFile> changes,
    _MutableGitFile incoming,
  ) {
    final existing = changes[incoming.path];
    if (existing == null) {
      changes[incoming.path] = incoming;
      return;
    }
    existing.merge(incoming);
  }

  int _compareFiles(SessionGitFile a, SessionGitFile b) {
    final updatedCompare =
        (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return a.path.compareTo(b.path);
  }

  Map<String, String> _buildFileIndex(
    List<SessionFile> files, {
    required String rootPath,
  }) {
    final result = <String, String>{};
    for (final file in files) {
      final normalized = _normalizePath(file.filePath);
      result[normalized] = file.id;
      result.putIfAbsent(_fileName(normalized), () => file.id);
      if (rootPath.isNotEmpty && normalized.startsWith('$rootPath/')) {
        result.putIfAbsent(
          normalized.substring(rootPath.length + 1),
          () => file.id,
        );
      } else if (rootPath.isNotEmpty && !normalized.startsWith('/')) {
        result.putIfAbsent('$rootPath/$normalized', () => file.id);
      }
    }
    return result;
  }

  String? _lookupFileId(Map<String, String> fileIdsByPath, String path) {
    return fileIdsByPath[_normalizePath(path)] ??
        fileIdsByPath[_fileName(path)];
  }

  String _resolveRootPath(Session session) {
    return _firstNonEmpty([
          _stringValue(session.metadata?['path']),
          session.path,
        ]) ??
        '';
  }

  String? _resolveBranch(Session session) {
    for (final source in [session.metadata, session.agentState]) {
      final branch = _searchString(
        source,
        const {'branch', 'branchName', 'currentBranch', 'gitBranch'},
      );
      if (branch != null) {
        return branch;
      }
    }
    return null;
  }

  String? _searchString(
    dynamic value,
    Set<String> keys, {
    int depth = 0,
  }) {
    if (depth > 4) {
      return null;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (keys.contains(entry.key.toString())) {
          final text = _stringValue(entry.value);
          if (text != null) {
            return text;
          }
        }
      }
      for (final nested in value.values) {
        final result = _searchString(nested, keys, depth: depth + 1);
        if (result != null) {
          return result;
        }
      }
    }
    if (value is List) {
      for (final nested in value) {
        final result = _searchString(nested, keys, depth: depth + 1);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  String? _extractPrimaryPath(Map<String, dynamic> arguments) {
    const keys = [
      'file_path',
      'path',
      'cwd',
      'root',
      'uri',
      'target_file',
    ];
    for (final key in keys) {
      final value = arguments[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    final locations = arguments['locations'];
    if (locations is List && locations.isNotEmpty) {
      final first = locations.first;
      if (first is Map && first['path'] is String) {
        return first['path'] as String;
      }
    }
    return null;
  }

  String? _extractDiff(ToolInfo tool) {
    final arguments = tool.arguments;
    final directPatch = arguments['patch'] ?? arguments['diff'];
    if (directPatch is String && directPatch.trim().isNotEmpty) {
      return directPatch.trimRight();
    }

    final oldString = arguments['old_string'] ?? arguments['oldText'];
    final newString = arguments['new_string'] ?? arguments['newText'];
    if (oldString is String && newString is String) {
      return _buildUnifiedDiff(
        path: _extractPrimaryPath(arguments) ?? 'untitled',
        oldContent: oldString,
        newContent: newString,
      );
    }

    final edits = arguments['edits'];
    if (edits is List && edits.isNotEmpty) {
      final buffer = StringBuffer();
      for (final edit in edits.whereType<Map>()) {
        final oldValue = edit['old_string']?.toString() ?? '';
        final newValue = edit['new_string']?.toString() ?? '';
        final path = edit['path']?.toString() ??
            edit['file_path']?.toString() ??
            _extractPrimaryPath(arguments) ??
            'untitled';
        final patch = _buildUnifiedDiff(
          path: path,
          oldContent: oldValue,
          newContent: newValue,
        );
        if (patch == null) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.writeln(patch);
      }
      if (buffer.isNotEmpty) {
        return buffer.toString().trimRight();
      }
    }

    final result = tool.result;
    if (result != null &&
        (result.contains('@@') ||
            result.contains('diff --git') ||
            result.contains('*** Begin Patch'))) {
      return result.trimRight();
    }
    return null;
  }

  String? _extractPathFromDiff(String diff) {
    for (final line in diff.split('\n')) {
      if (line.startsWith('+++ b/')) {
        return line.substring(6).trim();
      }
      if (line.startsWith('--- a/')) {
        return line.substring(6).trim();
      }
    }
    return null;
  }

  SessionGitFileStatus _inferStatus({
    required String toolName,
    required String? diff,
    required String? oldText,
    required String? newText,
  }) {
    if (diff != null) {
      if (diff.contains('new file mode') || diff.contains('--- /dev/null')) {
        return SessionGitFileStatus.added;
      }
      if (diff.contains('deleted file mode') ||
          diff.contains('+++ /dev/null')) {
        return SessionGitFileStatus.deleted;
      }
      if (diff.contains('rename from') || diff.contains('rename to')) {
        return SessionGitFileStatus.renamed;
      }
    }
    if (toolName.contains('write') && (oldText == null || oldText.isEmpty)) {
      return SessionGitFileStatus.added;
    }
    return SessionGitFileStatus.modified;
  }

  (int, int) _countDiffLines(String? diff) {
    if (diff == null || diff.trim().isEmpty) {
      return (0, 0);
    }
    var added = 0;
    var removed = 0;
    for (final line in diff.split('\n')) {
      if (line.startsWith('+++') || line.startsWith('---')) {
        continue;
      }
      if (line.startsWith('+')) {
        added += 1;
      } else if (line.startsWith('-')) {
        removed += 1;
      }
    }
    return (added, removed);
  }

  String? _buildUnifiedDiff({
    required String path,
    String? oldContent,
    String? newContent,
  }) {
    if ((oldContent == null || oldContent.isEmpty) &&
        (newContent == null || newContent.isEmpty)) {
      return null;
    }

    final oldLines = oldContent?.split('\n') ?? const <String>[];
    final newLines = newContent?.split('\n') ?? const <String>[];
    final buffer = StringBuffer()
      ..writeln('diff --git a/$path b/$path')
      ..writeln('--- ${oldContent == null ? '/dev/null' : 'a/$path'}')
      ..writeln('+++ ${newContent == null ? '/dev/null' : 'b/$path'}')
      ..writeln('@@ -1,${oldLines.length} +1,${newLines.length} @@');

    final maxLength = math.max(oldLines.length, newLines.length);
    for (var index = 0; index < maxLength; index += 1) {
      final oldLine = index < oldLines.length ? oldLines[index] : null;
      final newLine = index < newLines.length ? newLines[index] : null;
      if (oldLine == newLine) {
        if (oldLine != null) {
          buffer.writeln(' $oldLine');
        }
        continue;
      }
      if (oldLine != null) {
        buffer.writeln('-$oldLine');
      }
      if (newLine != null) {
        buffer.writeln('+$newLine');
      }
    }
    return buffer.toString().trimRight();
  }

  DateTime? _latestUpdatedAt(List<SessionGitFile> files) {
    DateTime? latest;
    for (final file in files) {
      final updatedAt = file.updatedAt;
      if (updatedAt == null) {
        continue;
      }
      if (latest == null || updatedAt.isAfter(latest)) {
        latest = updatedAt;
      }
    }
    return latest;
  }

  String _normalizePath(String path) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.startsWith('a/')) {
      normalized = normalized.substring(2);
    } else if (normalized.startsWith('b/')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }

  String _fileName(String path) {
    final normalized = _normalizePath(path);
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  SessionGitFileStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'added':
      case 'a':
        return SessionGitFileStatus.added;
      case 'deleted':
      case 'd':
        return SessionGitFileStatus.deleted;
      case 'renamed':
      case 'r':
        return SessionGitFileStatus.renamed;
      case 'untracked':
      case 'u':
      case '?':
        return SessionGitFileStatus.untracked;
      default:
        return SessionGitFileStatus.modified;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  int? _firstPositive(List<int?> values) {
    for (final value in values) {
      if (value != null && value >= 0) {
        return value;
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _StructuredGitRepository {
  const _StructuredGitRepository({
    required this.branch,
    required this.stagedFiles,
    required this.unstagedFiles,
    required this.totalAddedLines,
    required this.totalRemovedLines,
  });

  final String branch;
  final List<SessionGitFile> stagedFiles;
  final List<SessionGitFile> unstagedFiles;
  final int totalAddedLines;
  final int totalRemovedLines;
}

class _MutableGitFile {
  _MutableGitFile({
    required this.path,
    required this.fileName,
    required this.status,
    required this.isStaged,
    required this.addedLines,
    required this.removedLines,
    required this.priority,
    this.fileId,
    this.previousPath,
    this.diff,
    this.updatedAt,
  });

  factory _MutableGitFile.fromFile(SessionGitFile file,
      {required int priority}) {
    return _MutableGitFile(
      path: file.path,
      fileName: file.fileName,
      status: file.status,
      fileId: file.fileId,
      previousPath: file.previousPath,
      isStaged: file.isStaged,
      addedLines: file.addedLines,
      removedLines: file.removedLines,
      diff: file.diff,
      updatedAt: file.updatedAt,
      priority: priority,
    );
  }

  final String path;
  String fileName;
  SessionGitFileStatus status;
  String? fileId;
  String? previousPath;
  bool isStaged;
  int addedLines;
  int removedLines;
  String? diff;
  DateTime? updatedAt;
  int priority;

  void merge(_MutableGitFile next) {
    final hasHigherPriority = next.priority > priority;
    final isNewer = next.updatedAt != null &&
        (updatedAt == null || next.updatedAt!.isAfter(updatedAt!));

    if (hasHigherPriority || (!hasHigherPriority && isNewer)) {
      status = next.status;
      isStaged = next.isStaged;
      addedLines = next.addedLines;
      removedLines = next.removedLines;
      diff = next.diff ?? diff;
      updatedAt = next.updatedAt ?? updatedAt;
      priority = next.priority;
      previousPath = next.previousPath ?? previousPath;
    } else if (diff == null && next.diff != null) {
      diff = next.diff;
    }

    fileId ??= next.fileId;
    if (next.fileName.isNotEmpty) {
      fileName = next.fileName;
    }
  }

  SessionGitFile toFile() {
    return SessionGitFile(
      path: path,
      fileName: fileName,
      status: status,
      fileId: fileId,
      previousPath: previousPath,
      isStaged: isStaged,
      addedLines: addedLines,
      removedLines: removedLines,
      diff: diff,
      updatedAt: updatedAt,
    );
  }
}
