import 'dart:convert';

import '../domain/reducer.dart';
import '../domain/session_files_models.dart';
import '../domain/session_models.dart';

class DerivedSessionFilesService {
  const DerivedSessionFilesService();

  List<SessionFile> deriveFiles({
    required String sessionId,
    required List<ReducerMessage> messages,
    Session? session,
  }) {
    final rootPath = _normalizePath(session?.path);
    final files = <String, _DerivedSessionFile>{};

    void absorb(
      String? rawPath, {
      required DateTime timestamp,
      String? content,
      int? size,
      String? mimeType,
    }) {
      final normalizedPath = _normalizePath(rawPath);
      if (normalizedPath == null ||
          _shouldIgnorePath(normalizedPath, rootPath: rootPath)) {
        return;
      }
      final entry = files.putIfAbsent(
        normalizedPath,
        () => _DerivedSessionFile(
          sessionId: sessionId,
          path: normalizedPath,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      entry.absorb(
        timestamp: timestamp,
        content: content,
        size: size,
        mimeType: mimeType,
      );
    }

    for (final rawPath in _extractStructuredPaths(session)) {
      absorb(
        rawPath,
        timestamp: session?.updatedAt ?? DateTime.now(),
      );
    }

    for (final message in messages) {
      final tool = message.tool;
      if (tool == null) {
        continue;
      }

      final candidatePaths = _extractToolPaths(tool).toList();
      if (tool.name.toLowerCase() == 'file') {
        candidatePaths.addAll([
          _stringValue(tool.arguments['name']),
          _stringValue(tool.arguments['path']),
        ].whereType<String>());
      }

      if (candidatePaths.isEmpty) {
        continue;
      }

      for (final rawPath in candidatePaths) {
        final normalizedPath = _normalizePath(rawPath);
        if (normalizedPath == null ||
            _shouldIgnorePath(normalizedPath, rootPath: rootPath)) {
          continue;
        }
        absorb(
          normalizedPath,
          timestamp: message.createdAt,
          content: _extractToolContentForPath(
            tool,
            normalizedPath,
            rootPath: rootPath,
          ),
          size: _toInt(tool.arguments['size']),
          mimeType: _stringValue(tool.arguments['mimeType']) ??
              _guessMimeType(normalizedPath),
        );
      }
    }

    final items = files.values.map((entry) => entry.toSessionFile()).toList()
      ..sort((a, b) {
        final byTime = b.updatedAt.compareTo(a.updatedAt);
        if (byTime != 0) {
          return byTime;
        }
        return a.filePath.compareTo(b.filePath);
      });
    return items;
  }

  SessionFile? findDerivedFileByPath({
    required String sessionId,
    required String filePath,
    required List<ReducerMessage> messages,
    Session? session,
  }) {
    final normalizedTarget = _normalizePath(filePath);
    if (normalizedTarget == null) {
      return null;
    }
    final rootPath = _normalizePath(session?.path);
    for (final file in deriveFiles(
      sessionId: sessionId,
      messages: messages,
      session: session,
    )) {
      if (_pathsMatch(file.filePath, normalizedTarget, rootPath: rootPath)) {
        return file;
      }
    }
    return null;
  }

  String? deriveFileContent({
    required String filePath,
    required List<ReducerMessage> messages,
    Session? session,
  }) {
    final normalizedTarget = _normalizePath(filePath);
    if (normalizedTarget == null) {
      return null;
    }
    final rootPath = _normalizePath(session?.path);

    for (final message in messages.reversed) {
      final tool = message.tool;
      if (tool == null) {
        continue;
      }
      final content = _extractToolContentForPath(
        tool,
        normalizedTarget,
        rootPath: rootPath,
      );
      if (content != null && content.trim().isNotEmpty) {
        return content.trimRight();
      }
    }
    return null;
  }

  Iterable<String> _extractStructuredPaths(Session? session) sync* {
    if (session == null) {
      return;
    }

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
      for (final key in const ['stagedFiles', 'unstagedFiles', 'files']) {
        final files = candidate[key];
        if (files is! List) {
          continue;
        }
        for (final item in files.whereType<Map>()) {
          final map = _asMap(item);
          final path = _firstNonEmpty([
            map?['filePath']?.toString(),
            map?['path']?.toString(),
            map?['fullPath']?.toString(),
            map?['fileName']?.toString(),
          ]);
          if (path != null) {
            yield path;
          }
        }
      }
    }
  }

  Iterable<String> _extractToolPaths(ToolInfo tool) sync* {
    final arguments = tool.arguments;
    final scalars = <dynamic>[
      arguments['file_path'],
      arguments['path'],
      arguments['uri'],
      arguments['target_file'],
      arguments['source_path'],
      arguments['old_path'],
      arguments['new_path'],
      arguments['destination_path'],
      arguments['output_file'],
    ];

    for (final value in scalars) {
      final path = _stringValue(value);
      if (path != null) {
        yield path;
      }
    }

    for (final key in const ['files', 'paths']) {
      final list = arguments[key];
      if (list is! List) {
        continue;
      }
      for (final item in list) {
        if (item is String && item.trim().isNotEmpty) {
          yield item.trim();
          continue;
        }
        final map = _asMap(item);
        final path = _firstNonEmpty([
          map?['path']?.toString(),
          map?['file_path']?.toString(),
          map?['name']?.toString(),
        ]);
        if (path != null) {
          yield path;
        }
      }
    }

    final edits = arguments['edits'];
    if (edits is List) {
      for (final edit in edits.whereType<Map>()) {
        final map = _asMap(edit);
        final path = _firstNonEmpty([
          map?['path']?.toString(),
          map?['file_path']?.toString(),
          map?['target_file']?.toString(),
        ]);
        if (path != null) {
          yield path;
        }
      }
    }

    final locations = arguments['locations'];
    if (locations is List) {
      for (final location in locations.whereType<Map>()) {
        final map = _asMap(location);
        final path = _firstNonEmpty([
          map?['path']?.toString(),
          map?['file_path']?.toString(),
        ]);
        if (path != null) {
          yield path;
        }
      }
    }

    final diff = _extractDiff(tool);
    if (diff != null) {
      yield* _extractPathsFromDiff(diff);
    }
  }

  String? _extractToolContentForPath(
    ToolInfo tool,
    String normalizedTarget, {
    String? rootPath,
  }) {
    final arguments = tool.arguments;

    final pathCandidates = _extractToolPaths(tool);
    final hasPathMatch = pathCandidates.any(
      (candidate) => _pathsMatch(
        candidate,
        normalizedTarget,
        rootPath: rootPath,
      ),
    );

    final directContent = _firstNonEmpty([
      _stringValue(arguments['content']),
      _stringValue(arguments['text']),
      _stringValue(arguments['new_string']),
      _stringValue(arguments['newText']),
    ]);
    if (hasPathMatch && directContent != null) {
      return directContent;
    }

    final edits = arguments['edits'];
    if (edits is List) {
      for (final edit in edits.reversed.whereType<Map>()) {
        final map = _asMap(edit);
        final path = _firstNonEmpty([
          map?['path']?.toString(),
          map?['file_path']?.toString(),
          map?['target_file']?.toString(),
        ]);
        if (!_pathsMatch(path, normalizedTarget, rootPath: rootPath)) {
          continue;
        }
        final content = _firstNonEmpty([
          map?['new_string']?.toString(),
          map?['newText']?.toString(),
        ]);
        if (content != null) {
          return content;
        }
      }
    }

    final diff = _extractDiff(tool);
    if (diff != null) {
      final paths = _extractPathsFromDiff(diff);
      if (paths.any(
        (candidate) => _pathsMatch(
          candidate,
          normalizedTarget,
          rootPath: rootPath,
        ),
      )) {
        return diff;
      }
    }

    if (_looksLikeReadableResult(tool.name) &&
        tool.result != null &&
        tool.result!.trim().isNotEmpty &&
        hasPathMatch) {
      return tool.result!.trimRight();
    }

    if (tool.name.toLowerCase() == 'file' &&
        tool.result != null &&
        tool.result!.trim().isNotEmpty &&
        hasPathMatch) {
      return tool.result!.trimRight();
    }

    return null;
  }

  Iterable<String> _extractPathsFromDiff(String diff) sync* {
    for (final line in diff.split('\n')) {
      if (line.startsWith('+++ b/')) {
        yield line.substring(6).trim();
        continue;
      }
      if (line.startsWith('--- a/')) {
        yield line.substring(6).trim();
        continue;
      }
      if (line.startsWith('diff --git ')) {
        final match = RegExp(r'^diff --git a/(.+?) b/(.+)$').firstMatch(line);
        if (match != null) {
          yield match.group(2)!.trim();
        }
        continue;
      }
      if (line.startsWith('*** Add File: ') ||
          line.startsWith('*** Update File: ') ||
          line.startsWith('*** Delete File: ')) {
        yield line.split(':').last.trim();
      }
    }
  }

  String? _extractDiff(ToolInfo tool) {
    final arguments = tool.arguments;
    final directPatch = arguments['patch'] ?? arguments['diff'];
    if (directPatch is String && directPatch.trim().isNotEmpty) {
      return directPatch.trimRight();
    }

    final oldString = _stringValue(arguments['old_string']) ??
        _stringValue(arguments['oldText']);
    final newString = _stringValue(arguments['new_string']) ??
        _stringValue(arguments['newText']);
    final path = _firstNonEmpty([
      _stringValue(arguments['file_path']),
      _stringValue(arguments['path']),
      _stringValue(arguments['target_file']),
    ]);
    if (path != null && (oldString != null || newString != null)) {
      return _buildUnifiedDiff(
        path: path,
        oldContent: oldString,
        newContent: newString,
      );
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

    final maxLength =
        oldLines.length > newLines.length ? oldLines.length : newLines.length;
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

  bool _looksLikeReadableResult(String toolName) {
    final lowerTool = toolName.toLowerCase();
    return lowerTool.contains('read') ||
        lowerTool.contains('cat') ||
        lowerTool.contains('open') ||
        lowerTool.contains('view');
  }

  bool _pathsMatch(
    String? candidate,
    String target, {
    String? rootPath,
  }) {
    final normalizedCandidate = _normalizePath(candidate);
    if (normalizedCandidate == null) {
      return false;
    }
    if (normalizedCandidate == target) {
      return true;
    }
    if (rootPath != null && rootPath.isNotEmpty) {
      if (normalizedCandidate == '$rootPath/$target') {
        return true;
      }
      if (target == '$rootPath/$normalizedCandidate') {
        return true;
      }
      if (target.startsWith('$rootPath/') &&
          normalizedCandidate == target.substring(rootPath.length + 1)) {
        return true;
      }
      if (normalizedCandidate.startsWith('$rootPath/') &&
          target == normalizedCandidate.substring(rootPath.length + 1)) {
        return true;
      }
    }
    return _fileName(normalizedCandidate) == _fileName(target);
  }

  bool _shouldIgnorePath(String path, {String? rootPath}) {
    if (path.isEmpty ||
        path == '/dev/null' ||
        path == 'untitled' ||
        path == '.' ||
        path.endsWith('/')) {
      return true;
    }
    if (rootPath != null && path == rootPath) {
      return true;
    }
    return false;
  }

  String? _normalizePath(String? rawPath) {
    if (rawPath == null) {
      return null;
    }
    final trimmed = rawPath.trim();
    final decoded = () {
      try {
        return Uri.decodeComponent(trimmed);
      } catch (_) {
        return trimmed;
      }
    }();
    var normalized = decoded.replaceAll('\\', '/').replaceAll('file://', '');
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('a/')) {
      normalized = normalized.substring(2);
    } else if (normalized.startsWith('b/')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith('"') && normalized.endsWith('"')) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
    return normalized.isEmpty ? null : normalized;
  }

  String _fileName(String path) {
    final normalized = _normalizePath(path) ?? path;
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
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
    if (lower.endsWith('.dart') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.tsx') ||
        lower.endsWith('.jsx') ||
        lower.endsWith('.py') ||
        lower.endsWith('.go') ||
        lower.endsWith('.java') ||
        lower.endsWith('.kt') ||
        lower.endsWith('.swift') ||
        lower.endsWith('.sh') ||
        lower.endsWith('.zsh') ||
        lower.endsWith('.bash')) {
      return 'text/plain';
    }
    return null;
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

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
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
}

class _DerivedSessionFile {
  _DerivedSessionFile({
    required this.sessionId,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
  });

  final String sessionId;
  final String path;
  DateTime createdAt;
  DateTime updatedAt;
  int? size;
  String? mimeType;
  String? content;

  void absorb({
    required DateTime timestamp,
    String? content,
    int? size,
    String? mimeType,
  }) {
    if (timestamp.isBefore(createdAt)) {
      createdAt = timestamp;
    }
    if (timestamp.isAfter(updatedAt)) {
      updatedAt = timestamp;
    }
    if (content != null && content.isNotEmpty) {
      this.content = content;
      this.size = size ?? utf8.encode(content).length;
    } else if (size != null) {
      this.size = size;
    }
    if (mimeType != null && mimeType.isNotEmpty) {
      this.mimeType = mimeType;
    }
  }

  SessionFile toSessionFile() {
    return SessionFile(
      id: 'derived:${base64Url.encode(utf8.encode(path))}',
      sessionId: sessionId,
      filePath: path,
      fileName: path.split('/').last,
      size: size,
      mimeType: mimeType,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: updatedAt.millisecondsSinceEpoch,
    );
  }
}
