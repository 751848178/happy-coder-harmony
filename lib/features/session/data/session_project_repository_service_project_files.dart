part of 'session_project_repository_service.dart';

Future<List<SessionFile>> _loadProjectFiles({
  required Session session,
  required SessionServiceNotifier notifier,
  required List<SessionGitFile> changedFiles,
}) async {
  final rootPath = session.path;
  if (rootPath == null || rootPath.trim().isEmpty) {
    return const [];
  }
  var stdout = '';
  final ripgrepResponse = await notifier.executeSessionRipgrep(
    sessionId: session.id,
    args: const ['--files', '--follow', '--hidden'],
    cwd: rootPath,
  );
  if (ripgrepResponse.success && ripgrepResponse.stdout.trim().isNotEmpty) {
    stdout = ripgrepResponse.stdout;
  }
  if (stdout.trim().isEmpty) {
    final bashResponse = await notifier.executeSessionBash(
      sessionId: session.id,
      command: 'rg --files --follow --hidden',
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
