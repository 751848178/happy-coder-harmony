part of 'file_viewer_screen.dart';

extension on _FileViewerScreenState {
  String _formattedContent() {
    final content = _content ?? '';
    if (_presentation == _FilePresentation.json) {
      try {
        final decoded = jsonDecode(content);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return content;
      }
    }
    return content;
  }

  String _resolveLanguage() {
    final mime =
        (widget.mimeType ?? _resolvedFile?.mimeType ?? '').toLowerCase();
    final name = (_resolvedFile?.fileName ?? widget.fileName).toLowerCase();

    if (name.endsWith('.dart')) return 'dart';
    if (name.endsWith('.ts') || name.endsWith('.tsx')) return 'typescript';
    if (name.endsWith('.js') || name.endsWith('.jsx')) return 'javascript';
    if (name.endsWith('.json') || mime == 'application/json') return 'json';
    if (name.endsWith('.md')) return 'markdown';
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return 'yaml';
    if (name.endsWith('.sh') ||
        name.endsWith('.bash') ||
        mime.contains('shell')) {
      return 'bash';
    }
    if (name.endsWith('.py')) return 'python';
    if (name.endsWith('.go')) return 'go';
    if (name.endsWith('.java')) return 'java';
    if (name.endsWith('.kt')) return 'kotlin';
    if (name.endsWith('.swift')) return 'swift';
    if (name.endsWith('.rs')) return 'rust';
    if (name.endsWith('.html')) return 'html';
    if (name.endsWith('.css')) return 'css';
    if (name.endsWith('.sql')) return 'sql';
    if (mime.contains('xml') || name.endsWith('.xml')) return 'xml';
    return 'plaintext';
  }
}

MarkdownStyleSheet fileViewerMarkdownStyleSheet() {
  return MarkdownStyleSheet(
    p: const TextStyle(
      fontSize: 14,
      height: 1.6,
      color: AppTheme.textPrimary,
    ),
    h1: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    ),
    h2: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    ),
    h3: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    ),
    code: const TextStyle(
      fontFamily: AppTheme.fontFamilyMono,
      fontSize: 12.5,
      color: AppTheme.textPrimary,
      backgroundColor: AppTheme.neutral100,
    ),
    a: const TextStyle(
      color: AppTheme.brandColor,
      decoration: TextDecoration.underline,
    ),
    blockquote: TextStyle(
      color: AppTheme.neutral700.withValues(alpha: 0.9),
      fontStyle: FontStyle.italic,
    ),
  );
}
