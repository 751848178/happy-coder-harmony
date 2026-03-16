part of 'session_project_repository_service.dart';

String _shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

bool _looksBinary(String content) {
  if (content.isEmpty) {
    return false;
  }
  if (content.contains('\u0000')) {
    return true;
  }
  final nonPrintableCount = content.runes.where((code) {
    return code < 32 && code != 9 && code != 10 && code != 13;
  }).length;
  return nonPrintableCount / content.length > 0.1;
}

String _basename(String path) {
  final segments = path.split('/');
  return segments.isEmpty ? path : segments.last;
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
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  return null;
}

SessionGitFileStatus _statusFromCode(String code) {
  switch (code) {
    case 'A':
      return SessionGitFileStatus.added;
    case 'D':
      return SessionGitFileStatus.deleted;
    case 'R':
    case 'C':
      return SessionGitFileStatus.renamed;
    case '?':
      return SessionGitFileStatus.untracked;
    default:
      return SessionGitFileStatus.modified;
  }
}
