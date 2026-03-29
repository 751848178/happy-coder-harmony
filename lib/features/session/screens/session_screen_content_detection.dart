part of 'session_screen.dart';

final RegExp _markdownHeadingPattern = RegExp(r'(^|\n)\s{0,3}#{1,6}\s');
final RegExp _markdownBulletPattern = RegExp(r'(^|\n)\s*[-*+]\s+');
final RegExp _markdownOrderedPattern = RegExp(r'(^|\n)\s*\d+\.\s+');
final RegExp _markdownTablePattern = RegExp(r'(^|\n)\s*\|.+\|');
final RegExp _markdownLinkPattern = RegExp(r'\[[^\]]+\]\([^)]+\)');
final RegExp _markdownQuotePattern = RegExp(r'(^|\n)>\s+');
final RegExp _diffHeaderPattern = RegExp(r'(^|\n)[+-]{3}\s');
final RegExp _dockerfilePattern = RegExp(
  r'(^|\n)\s*(FROM|RUN|COPY|ADD|WORKDIR|ENV|CMD|ENTRYPOINT|EXPOSE|ARG)\b',
  caseSensitive: false,
);
final RegExp _yamlKeyPattern = RegExp("^\\s*[\\w\\-./\"']+\\s*:\\s*.*\$");
final RegExp _envFilePattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=');
final RegExp _nginxPattern = RegExp(
  r'(^|\n)\s*(server|location|upstream)\s*\{|(^|\n)\s*listen\s+\d+',
  caseSensitive: false,
);
final RegExp _shellPattern = RegExp(
  r'(^|\n)\s*(npm|pnpm|yarn|git|docker|cd|ls|cat|echo|export|curl|chmod|./)',
  caseSensitive: false,
);
final RegExp _sqlPattern = RegExp(
  r'(^|\n)\s*(select|insert|update|delete|create|alter|drop)\b',
  caseSensitive: false,
);
final RegExp _xmlPattern = RegExp(r'<[A-Za-z][^>]*>');
final RegExp _iniPattern = RegExp(r'(^|\n)\s*\[[^\]]+\]\s*$');
final RegExp _indentedCodePattern = RegExp(r'^\s{2,}\S');
final Map<String, bool> _markdownContentCache = <String, bool>{};
final Map<String, String> _structuredLanguageCache = <String, String>{};
const int _contentDetectionCacheLimit = 120;

bool _looksLikeMarkdownContentValue(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return false;
  }
  final cached = _markdownContentCache[normalized];
  if (cached != null) {
    return cached;
  }
  final result = normalized.contains('```') ||
      _markdownHeadingPattern.hasMatch(normalized) ||
      _markdownBulletPattern.hasMatch(normalized) ||
      _markdownOrderedPattern.hasMatch(normalized) ||
      _markdownTablePattern.hasMatch(normalized) ||
      _markdownLinkPattern.hasMatch(normalized) ||
      _markdownQuotePattern.hasMatch(normalized);
  _storeContentDetectionCache(_markdownContentCache, normalized, result);
  return result;
}

String _detectStructuredLanguage(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final cached = _structuredLanguageCache[normalized];
  if (cached != null) {
    return cached;
  }

  String detected = '';
  if ((normalized.startsWith('{') || normalized.startsWith('[')) &&
      _canDecodeJson(normalized)) {
    detected = 'json';
  } else if (_looksLikeDiff(normalized)) {
    detected = 'diff';
  } else if (_looksLikeDockerfile(normalized)) {
    detected = 'dockerfile';
  } else if (_looksLikeYaml(normalized)) {
    detected = 'yaml';
  } else if (_looksLikeEnvFile(normalized)) {
    detected = 'bash';
  } else if (_looksLikeNginx(normalized)) {
    detected = 'nginx';
  } else if (_looksLikeShell(normalized)) {
    detected = 'bash';
  } else if (_looksLikeSql(normalized)) {
    detected = 'sql';
  } else if (_looksLikeXml(normalized)) {
    detected = 'xml';
  } else if (_looksLikeIni(normalized)) {
    detected = 'ini';
  } else if (_looksLikeCodeLikeBlock(normalized)) {
    detected = 'text';
  }
  _storeContentDetectionCache(_structuredLanguageCache, normalized, detected);
  return detected;
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
    _diffHeaderPattern.hasMatch(value);

bool _looksLikeDockerfile(String value) => _dockerfilePattern.hasMatch(value);

bool _looksLikeYaml(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.length < 2) {
    return false;
  }
  final keyedLines = lines.where((line) => _yamlKeyPattern.hasMatch(line));
  return keyedLines.length >= 2;
}

bool _looksLikeEnvFile(String value) {
  final lines =
      value.split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (lines.isEmpty) {
    return false;
  }
  final matched = lines.where(
    (line) => _envFilePattern.hasMatch(line.trim()),
  );
  return matched.length >= 2;
}

bool _looksLikeNginx(String value) => _nginxPattern.hasMatch(value);

bool _looksLikeShell(String value) => _shellPattern.hasMatch(value);

bool _looksLikeSql(String value) => _sqlPattern.hasMatch(value);

bool _looksLikeXml(String value) =>
    value.startsWith('<') && _xmlPattern.hasMatch(value);

bool _looksLikeIni(String value) => _iniPattern.hasMatch(value);

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
    if (_indentedCodePattern.hasMatch(line)) {
      scored++;
    }
  }

  return scored >= lines.length;
}

void _storeContentDetectionCache<T>(
  Map<String, T> cache,
  String key,
  T value,
) {
  if (cache.length >= _contentDetectionCacheLimit) {
    cache.remove(cache.keys.first);
  }
  cache[key] = value;
}
