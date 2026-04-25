part of 'file_viewer_screen.dart';

String normalizeFileViewerLanguage(String language) {
  switch (language.toLowerCase()) {
    case 'ts':
    case 'tsx':
      return 'typescript';
    case 'js':
    case 'jsx':
      return 'javascript';
    case 'yml':
      return 'yaml';
    case 'shell':
    case 'sh':
    case 'zsh':
      return 'bash';
    default:
      return language.toLowerCase();
  }
}

bool canHighlightFileViewerLanguage(String language) {
  const supported = <String>{
    'bash',
    'css',
    'dart',
    'go',
    'html',
    'java',
    'javascript',
    'json',
    'kotlin',
    'markdown',
    'plaintext',
    'python',
    'rust',
    'sql',
    'swift',
    'typescript',
    'xml',
    'yaml',
  };
  return supported.contains(language);
}
