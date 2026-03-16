part of 'session_screen.dart';

extension _SessionScreenInlineCodePanelHelpers2 on _InlineCodePanelState {
  String _normalizeLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'ts':
        return 'typescript';
      case 'js':
        return 'javascript';
      case 'yml':
        return 'yaml';
      case 'dockerfile':
      case 'nginx':
      case 'ini':
        return 'plaintext';
      case 'shell':
      case 'bash':
      case 'zsh':
      case 'sh':
        return 'bash';
      default:
        return language;
    }
  }

  bool _canHighlightLanguage(String language) {
    const supported = {
      'bash',
      'c',
      'cpp',
      'css',
      'dart',
      'diff',
      'go',
      'html',
      'java',
      'javascript',
      'json',
      'kotlin',
      'markdown',
      'objc',
      'php',
      'plaintext',
      'python',
      'ruby',
      'rust',
      'sql',
      'swift',
      'typescript',
      'xml',
      'yaml',
    };
    return supported.contains(language);
  }
}
