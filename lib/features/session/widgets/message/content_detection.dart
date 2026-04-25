/// Content detection utilities for message rendering.
///
/// Extracted from session_screen's private namespace so that independent
/// message-bubble widgets and the presenter can use them without coupling
/// to the session screen mega-library.

// --- Regex patterns ---

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

// --- Caches ---

final Map<String, bool> _markdownContentCache = <String, bool>{};
final Map<String, String> _structuredLanguageCache = <String, String>{};
const int _contentDetectionCacheLimit = 120;

// --- Public API ---

bool looksLikeMarkdownContent(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) return false;
  final cached = _markdownContentCache[normalized];
  if (cached != null) return cached;
  final result = normalized.contains('```') ||
      _markdownHeadingPattern.hasMatch(normalized) ||
      _markdownBulletPattern.hasMatch(normalized) ||
      _markdownOrderedPattern.hasMatch(normalized) ||
      _markdownTablePattern.hasMatch(normalized) ||
      _markdownLinkPattern.hasMatch(normalized) ||
      _markdownQuotePattern.hasMatch(normalized);
  _storeCache(_markdownContentCache, normalized, result);
  return result;
}

String detectStructuredLanguage(String content) {
  final normalized = content.trim();
  if (normalized.isEmpty) return '';
  final cached = _structuredLanguageCache[normalized];
  if (cached != null) return cached;

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
  _storeCache(_structuredLanguageCache, normalized, detected);
  return detected;
}

void clearContentDetectionCaches() {
  _markdownContentCache.clear();
  _structuredLanguageCache.clear();
}

// --- Private helpers ---

bool _canDecodeJson(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) return true;
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) return true;
  return false;
}

bool _looksLikeDiff(String v) =>
    v.contains('diff --git') ||
    v.contains('*** Begin Patch') ||
    v.contains('\n@@') ||
    _diffHeaderPattern.hasMatch(v);

bool _looksLikeDockerfile(String v) => _dockerfilePattern.hasMatch(v);

bool _looksLikeYaml(String v) {
  final lines = v.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length < 2) return false;
  return lines.where((l) => _yamlKeyPattern.hasMatch(l)).length >= 2;
}

bool _looksLikeEnvFile(String v) {
  final lines = v.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return false;
  return lines.where((l) => _envFilePattern.hasMatch(l.trim())).length >= 2;
}

bool _looksLikeNginx(String v) => _nginxPattern.hasMatch(v);
bool _looksLikeShell(String v) => _shellPattern.hasMatch(v);
bool _looksLikeSql(String v) => _sqlPattern.hasMatch(v);
bool _looksLikeXml(String v) => v.startsWith('<') && _xmlPattern.hasMatch(v);
bool _looksLikeIni(String v) => _iniPattern.hasMatch(v);

bool _looksLikeCodeLikeBlock(String v) {
  final lines = v
      .split('\n')
      .map((l) => l.trimRight())
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.length < 3) return false;
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
    if (_indentedCodePattern.hasMatch(line)) scored++;
  }
  return scored >= lines.length;
}

void _storeCache<T>(Map<String, T> cache, String key, T value) {
  if (cache.length >= _contentDetectionCacheLimit) {
    cache.remove(cache.keys.first);
  }
  cache[key] = value;
}
