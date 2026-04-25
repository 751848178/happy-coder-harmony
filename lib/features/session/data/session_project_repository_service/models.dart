part of 'session_project_repository_service.dart';

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
