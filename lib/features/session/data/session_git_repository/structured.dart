part of 'session_git_repository.dart';

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
    final map = rawFile.map((key, value) => MapEntry(key.toString(), value));
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
          _firstNonEmpty([map['status']?.toString(), map['type']?.toString()]),
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
        diff:
            _firstNonEmpty([map['diff']?.toString(), map['patch']?.toString()]),
        updatedAt: _parseDateTime(
          map['updatedAt'] ?? map['lastUpdatedAt'] ?? map['timestamp'],
        ),
      ),
    );
  }
  return files;
}
