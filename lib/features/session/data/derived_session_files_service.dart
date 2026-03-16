import 'dart:convert';

import '../domain/reducer.dart';
import '../domain/session_files_models.dart';
import '../domain/session_models.dart';

part 'derived_session_files_service_content.dart';
part 'derived_session_files_service_models.dart';
part 'derived_session_files_service_paths.dart';
part 'derived_session_files_service_utils.dart';

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
      absorb(rawPath, timestamp: session?.updatedAt ?? DateTime.now());
    }

    for (final message in messages) {
      final tool = message.tool;
      if (tool == null) {
        continue;
      }
      final candidatePaths = _extractCandidatePaths(tool);
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

    return files.values.map((entry) => entry.toSessionFile()).toList()
      ..sort((a, b) {
        final byTime = b.updatedAt.compareTo(a.updatedAt);
        if (byTime != 0) {
          return byTime;
        }
        return a.filePath.compareTo(b.filePath);
      });
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
}
