part of 'session_project_repository_service.dart';

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
    statusOutput: statusResult.stdout,
    combinedDiffOutput: diffOutput,
  );
}

_GitStatusFilesData _parseGitStatusFilesV2({
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
    final file = match.group(3)!.trim();
    if (file.isEmpty) {
      continue;
    }
    final insertionsRaw = match.group(1)!;
    final deletionsRaw = match.group(2)!;
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
