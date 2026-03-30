part of 'session_screen.dart';

extension _SessionScreenInlineCodePanelHelpers on _InlineCodePanelState {
  bool _isTerminalLanguage(String language) {
    const terminalLanguages = {
      'shell',
      'bash',
      'sh',
      'zsh',
      'console',
      'terminal',
    };
    return terminalLanguages.contains(language.toLowerCase());
  }

  bool _isDiffLanguage(String language) => language.toLowerCase() == 'diff';

  String _languageLabel(String language) {
    if (language.isEmpty) {
      return '代码';
    }
    switch (language.toLowerCase()) {
      case 'shell':
      case 'bash':
      case 'zsh':
      case 'sh':
        return '终端';
      case 'diff':
        return '差异';
      case 'yaml':
        return 'YAML';
      case 'json':
        return 'JSON';
      case 'dockerfile':
        return 'Dockerfile';
      case 'nginx':
        return 'Nginx';
      case 'ini':
        return 'INI';
      default:
        return language;
    }
  }
}
