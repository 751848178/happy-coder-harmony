enum SessionGitFileStatus {
  modified,
  added,
  deleted,
  renamed,
  untracked,
}

class SessionGitFile {
  const SessionGitFile({
    required this.path,
    required this.fileName,
    required this.status,
    this.fileId,
    this.previousPath,
    this.isStaged = false,
    this.addedLines = 0,
    this.removedLines = 0,
    this.diff,
    this.updatedAt,
  });

  final String path;
  final String fileName;
  final SessionGitFileStatus status;
  final String? fileId;
  final String? previousPath;
  final bool isStaged;
  final int addedLines;
  final int removedLines;
  final String? diff;
  final DateTime? updatedAt;

  int get changedLines => addedLines + removedLines;
}

class SessionGitRepositoryView {
  const SessionGitRepositoryView({
    required this.rootPath,
    required this.branch,
    required this.stagedFiles,
    required this.unstagedFiles,
    required this.totalTrackedFiles,
    required this.totalAddedLines,
    required this.totalRemovedLines,
    required this.fromDerivedData,
    required this.sourceLabel,
    this.lastUpdatedAt,
  });

  final String rootPath;
  final String branch;
  final List<SessionGitFile> stagedFiles;
  final List<SessionGitFile> unstagedFiles;
  final int totalTrackedFiles;
  final int totalAddedLines;
  final int totalRemovedLines;
  final bool fromDerivedData;
  final String sourceLabel;
  final DateTime? lastUpdatedAt;

  SessionGitRepositoryView copyWith({
    String? rootPath,
    String? branch,
    List<SessionGitFile>? stagedFiles,
    List<SessionGitFile>? unstagedFiles,
    int? totalTrackedFiles,
    int? totalAddedLines,
    int? totalRemovedLines,
    bool? fromDerivedData,
    String? sourceLabel,
    DateTime? lastUpdatedAt,
  }) {
    return SessionGitRepositoryView(
      rootPath: rootPath ?? this.rootPath,
      branch: branch ?? this.branch,
      stagedFiles: stagedFiles ?? this.stagedFiles,
      unstagedFiles: unstagedFiles ?? this.unstagedFiles,
      totalTrackedFiles: totalTrackedFiles ?? this.totalTrackedFiles,
      totalAddedLines: totalAddedLines ?? this.totalAddedLines,
      totalRemovedLines: totalRemovedLines ?? this.totalRemovedLines,
      fromDerivedData: fromDerivedData ?? this.fromDerivedData,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  List<SessionGitFile> get changedFiles => [
        ...stagedFiles,
        ...unstagedFiles,
      ];

  bool get hasChanges => changedFiles.isNotEmpty;

  int get totalChangedFiles => changedFiles.length;
}
