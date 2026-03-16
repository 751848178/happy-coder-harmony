part of 'file_viewer_screen.dart';

extension on _FileViewerScreenState {
  Future<void> _loadFileContent() async {
    _beginLoadingFileContent();

    final normalizedPath = _normalizePath(widget.filePath);
    try {
      final rpcContent = await _loadRepositoryFileContent(normalizedPath);
      if (rpcContent != null) {
        if (!mounted) {
          return;
        }
        _showLoadedRepositoryContent(content: rpcContent.content);
        return;
      }

      final content = await _loadSessionRepositoryContent(normalizedPath);
      if (!mounted) {
        return;
      }
      _showLoadedSessionContent(
        resolvedFile: content.$1,
        content: content.$2,
      );
    } catch (error) {
      final derived =
          await _loadDerivedFileContent(normalizedPath: normalizedPath);
      if (derived != null) {
        if (!mounted) {
          return;
        }
        _showDerivedContent(resolvedFile: derived.$1, content: derived.$2);
        return;
      }
      if (!mounted) {
        return;
      }
      _showLoadError(error);
    }
  }

  Future<SessionProjectFileContent?> _loadRepositoryFileContent(
      String? normalizedPath) async {
    if (widget.sessionId == null ||
        widget.sessionId!.isEmpty ||
        normalizedPath == null ||
        normalizedPath.isEmpty) {
      return null;
    }

    final notifier = ref.read(sessionStateProvider.notifier);
    var session = notifier.getSession(widget.sessionId!);
    if (session == null) {
      await notifier.loadSessions(force: true);
      session = notifier.getSession(widget.sessionId!);
    }
    if (session == null) {
      return null;
    }

    return _projectRepositoryService.readFileContent(
      session: session,
      notifier: notifier,
      filePath: normalizedPath,
    );
  }

  Future<(SessionFile?, String)> _loadSessionRepositoryContent(
    String? normalizedPath,
  ) async {
    final repository = ref.read(sessionFilesRepositoryProvider);
    var resolvedFileId = widget.fileId;
    SessionFile? resolvedFile;

    if (widget.sessionId != null &&
        widget.sessionId!.isNotEmpty &&
        widget.filePath != null &&
        widget.filePath!.trim().isNotEmpty) {
      resolvedFile = await repository.findFileByPath(
        widget.sessionId!,
        normalizedPath!,
      );
      resolvedFileId ??= resolvedFile?.id;
    }

    if (resolvedFileId != null && resolvedFileId.startsWith('derived:')) {
      throw const SessionFilesApiException(
        message: '当前文件来自会话回退数据',
        statusCode: 404,
      );
    }
    if (resolvedFileId == null || resolvedFileId.isEmpty) {
      throw Exception('缺少可读取的文件标识');
    }

    final content = await repository.readFileContent(resolvedFileId);
    return (resolvedFile, content);
  }

  Future<(SessionFile?, String?)?> _loadDerivedFileContent({
    required String? normalizedPath,
  }) async {
    if (widget.sessionId == null ||
        widget.sessionId!.isEmpty ||
        normalizedPath == null ||
        normalizedPath.isEmpty) {
      return null;
    }

    final notifier = ref.read(sessionStateProvider.notifier);
    var session = notifier.getSession(widget.sessionId!);
    if (session == null) {
      await notifier.loadSessions(force: true);
      session = notifier.getSession(widget.sessionId!);
    }
    await notifier.loadSessionMessages(widget.sessionId!);
    final messages =
        notifier.getSessionMessages(widget.sessionId!)?.messages ?? const [];

    final derivedFile = _derivedFilesService.findDerivedFileByPath(
      sessionId: widget.sessionId!,
      filePath: normalizedPath,
      session: session,
      messages: messages,
    );
    final content = _derivedFilesService.deriveFileContent(
      filePath: normalizedPath,
      session: session,
      messages: messages,
    );
    if (derivedFile == null && (content == null || content.isEmpty)) {
      return null;
    }
    return (derivedFile, content);
  }

  String? _normalizePath(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return rawPath;
    }

    final trimmed = Uri.decodeComponent(rawPath.trim());
    try {
      var padded = trimmed.replaceAll('-', '+').replaceAll('_', '/');
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      final decoded = utf8.decode(base64Decode(padded));
      if (decoded.contains('/') || decoded.contains('\\')) {
        return decoded;
      }
    } catch (_) {
      // Fall back to the raw path when it is not base64-encoded.
    }

    return trimmed;
  }
}
