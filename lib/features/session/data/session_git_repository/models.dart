part of 'session_git_repository.dart';

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

  factory _MutableGitFile.fromFile(
    SessionGitFile file, {
    required int priority,
  }) {
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
