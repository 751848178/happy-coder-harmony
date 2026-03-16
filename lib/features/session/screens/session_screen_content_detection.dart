part of 'session_screen.dart';

bool _looksLikeMarkdownContentValue(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return false;
  }
  return normalized.contains('```') ||
      RegExp(r'(^|\n)\s{0,3}#{1,6}\s').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*[-*+]\s+').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*\d+\.\s+').hasMatch(normalized) ||
      RegExp(r'(^|\n)\s*\|.+\|').hasMatch(normalized) ||
      RegExp(r'\[[^\]]+\]\([^)]+\)').hasMatch(normalized) ||
      RegExp(r'(^|\n)>\s+').hasMatch(normalized);
}

String _detectStructuredLanguage(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return '';
  }

  if ((normalized.startsWith('{') || normalized.startsWith('[')) &&
      _canDecodeJson(normalized)) {
    return 'json';
  }
  if (_looksLikeDiff(normalized)) {
    return 'diff';
  }
  if (_looksLikeDockerfile(normalized)) {
    return 'dockerfile';
  }
  if (_looksLikeYaml(normalized)) {
    return 'yaml';
  }
  if (_looksLikeEnvFile(normalized)) {
    return 'bash';
  }
  if (_looksLikeNginx(normalized)) {
    return 'nginx';
  }
  if (_looksLikeShell(normalized)) {
    return 'bash';
  }
  if (_looksLikeSql(normalized)) {
    return 'sql';
  }
  if (_looksLikeXml(normalized)) {
    return 'xml';
  }
  if (_looksLikeIni(normalized)) {
    return 'ini';
  }
  if (_looksLikeCodeLikeBlock(normalized)) {
    return 'text';
  }
  return '';
}

bool _canDecodeJson(String value) {
  try {
    jsonDecode(value);
    return true;
  } catch (_) {
    return false;
  }
}

bool _looksLikeDiff(String value) =>
    value.contains('diff --git') ||
    value.contains('*** Begin Patch') ||
    value.contains('\n@@') ||
    RegExp(r'(^|\n)[+-]{3}\s').hasMatch(value);

bool _looksLikeDockerfile(String value) => RegExp(
      r'(^|\n)\s*(FROM|RUN|COPY|ADD|WORKDIR|ENV|CMD|ENTRYPOINT|EXPOSE|ARG)\b',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeYaml(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.length < 2) {
    return false;
  }
  final keyedLines = lines.where(
    (line) => RegExp("^\\s*[\\w\\-./\"']+\\s*:\\s*.*\$").hasMatch(line),
  );
  return keyedLines.length >= 2;
}

bool _looksLikeEnvFile(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.isEmpty) {
    return false;
  }
  final matched = lines.where(
    (line) => RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=').hasMatch(line.trim()),
  );
  return matched.length >= 2;
}

bool _looksLikeNginx(String value) => RegExp(
      r'(^|\n)\s*(server|location|upstream)\s*\{|(^|\n)\s*listen\s+\d+',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeShell(String value) => RegExp(
      r'(^|\n)\s*(npm|pnpm|yarn|git|docker|cd|ls|cat|echo|export|curl|chmod|./)',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeSql(String value) => RegExp(
      r'(^|\n)\s*(select|insert|update|delete|create|alter|drop)\b',
      caseSensitive: false,
    ).hasMatch(value);

bool _looksLikeXml(String value) =>
    value.startsWith('<') && RegExp(r'<[A-Za-z][^>]*>').hasMatch(value);

bool _looksLikeIni(String value) =>
    RegExp(r'(^|\n)\s*\[[^\]]+\]\s*$').hasMatch(value);

bool _looksLikeCodeLikeBlock(String value) {
  final lines = value
      .split('\n')
      .map((line) => line.trimRight())
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length < 3) {
    return false;
  }

  var scored = 0;
  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('#') ||
        trimmed.startsWith('- ') ||
        trimmed.startsWith('* ')) {
      scored++;
    }
    if (trimmed.contains('=') ||
        trimmed.contains(':') ||
        trimmed.contains('{') ||
        trimmed.contains('}') ||
        trimmed.contains('[') ||
        trimmed.contains(']') ||
        trimmed.contains(';')) {
      scored++;
    }
    if (RegExp(r'^\s{2,}\S').hasMatch(line)) {
      scored++;
    }
  }

  return scored >= lines.length;
}

