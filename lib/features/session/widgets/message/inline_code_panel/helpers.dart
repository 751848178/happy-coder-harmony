part of 'inline_code_panel.dart';

extension _InlineCodePanelHelpers on _InlineCodePanelState {
  Widget _buildHeader(List<String> lines, bool isTerminal, bool shouldCollapse,
      String normalizedCode) {
    return Row(children: [
      Icon(isTerminal ? Icons.terminal_rounded : Icons.code_rounded,
          size: 14, color: Colors.white70),
      const SizedBox(width: 6),
      Text(_languageLabel(widget.language),
          style: const TextStyle(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70)),
      const SizedBox(width: 8),
      Text('${lines.length} 行',
          style: const TextStyle(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: 11,
              color: Colors.white38)),
      const Spacer(),
      InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: normalizedCode));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('代码已复制'), duration: Duration(seconds: 2)));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('复制',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70))),
      ),
      if (shouldCollapse) const SizedBox(width: 8),
      if (shouldCollapse)
        InkWell(
          onTap: _toggleExpanded,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(_expanded ? '收起' : '展开',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF58A6FF)))),
        ),
    ]);
  }

  Widget _buildCodeContainer(String visibleCode, List<String> visibleLines,
      bool isDiff, bool isTerminal, bool shouldCollapse, List<String> lines) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: isDiff
            ? _buildDiffBlock(visibleLines)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTerminal) ...[
                    _buildLineNumbers(visibleLines.length),
                    const SizedBox(width: 12),
                    Container(
                        width: 1,
                        height: visibleLines.length * 21,
                        color: Colors.white10),
                    const SizedBox(width: 12),
                  ],
                  _buildCodeBody(visibleCode, isTerminal: isTerminal),
                ],
              ),
      ),
    );
  }

  Widget _buildLineNumbers(int count) {
    return Text(
      List<String>.generate(count, (i) => '${i + 1}').join('\n'),
      textAlign: TextAlign.right,
      style: const TextStyle(
          fontFamily: AppTheme.fontFamilyMono,
          fontSize: 12.5,
          height: 1.6,
          color: Colors.white38),
    );
  }

  Widget _buildCodeBody(String code, {required bool isTerminal}) {
    final normalizedLanguage = _normalizeLanguage(widget.language);
    final cacheKey = '$code\x00$normalizedLanguage';
    if (_cachedCodeBody != null && _cachedCodeBodyKey == cacheKey)
      return _cachedCodeBody!;

    final Widget result;
    if (isTerminal ||
        widget.language.isEmpty ||
        widget.language == 'text' ||
        !_canHighlightLanguage(normalizedLanguage)) {
      result = SelectableText(code,
          contextMenuBuilder:
              buildMessageActionContextMenu(widget.onMessageAction),
          style: TextStyle(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: 12.5,
              height: 1.6,
              color: isTerminal ? const Color(0xFFC9D1D9) : Colors.white));
    } else {
      result = HighlightView(code,
          language: normalizedLanguage,
          theme: vs2015Theme,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamilyMono,
              fontSize: 12.5,
              height: 1.6));
    }
    _cachedCodeBody = result;
    _cachedCodeBodyKey = cacheKey;
    return result;
  }

  Widget _buildDiffBlock(List<String> lines) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < lines.length; i++)
        Container(
          color: _diffBackground(lines[i]),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 28,
                    child: Text('${i + 1}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontFamily: AppTheme.fontFamilyMono,
                            fontSize: 12.5,
                            height: 1.6,
                            color: Colors.white38))),
                const SizedBox(width: 12),
                SelectableText(lines[i],
                    contextMenuBuilder:
                        buildMessageActionContextMenu(widget.onMessageAction),
                    style: TextStyle(
                        fontFamily: AppTheme.fontFamilyMono,
                        fontSize: 12.5,
                        height: 1.6,
                        color: _diffForeground(lines[i]))),
              ]),
        ),
    ]);
  }

  // --- helpers ---
  bool _isTerminalLanguage(String lang) => const {
        'shell',
        'bash',
        'sh',
        'zsh',
        'console',
        'terminal'
      }.contains(lang.toLowerCase());
  bool _isDiffLanguage(String lang) => lang.toLowerCase() == 'diff';
  String _languageLabel(String lang) {
    if (lang.isEmpty) return '代码';
    switch (lang.toLowerCase()) {
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
        return lang;
    }
  }

  String _normalizeLanguage(String lang) {
    switch (lang.toLowerCase()) {
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
        return lang;
    }
  }

  bool _canHighlightLanguage(String lang) => const {
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
        'yaml'
      }.contains(lang);
  Color _diffBackground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++'))
      return const Color(0x33238B4B);
    if (line.startsWith('-') && !line.startsWith('---'))
      return const Color(0x33DA3633);
    if (line.startsWith('@@')) return const Color(0x334A4A7A);
    return Colors.transparent;
  }

  Color _diffForeground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++'))
      return const Color(0xFF7EE787);
    if (line.startsWith('-') && !line.startsWith('---'))
      return const Color(0xFFFF7B72);
    if (line.startsWith('@@')) return const Color(0xFF79C0FF);
    return Colors.white;
  }
}
