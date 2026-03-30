part of 'session_screen.dart';

extension _SessionScreenInlineCodePanelRender on _InlineCodePanelState {
  Widget _buildLineNumbers(int count) {
    return Text(
      List<String>.generate(count, (index) => '${index + 1}').join('\n'),
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: AppTheme.fontFamilyMono,
        fontSize: 12.5,
        height: 1.6,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildCodeBody(
    String code, {
    required Color foregroundColor,
    required bool isTerminal,
  }) {
    final normalizedLanguage = _normalizeLanguage(widget.language);
    if (isTerminal ||
        widget.language.isEmpty ||
        widget.language == 'text' ||
        !_canHighlightLanguage(normalizedLanguage)) {
      return SelectableText(
        code,
        contextMenuBuilder: _buildMessageActionContextMenuBuilder(
          widget.onMessageAction,
        ),
        style: TextStyle(
          fontFamily: AppTheme.fontFamilyMono,
          fontSize: 12.5,
          height: 1.6,
          color: isTerminal ? const Color(0xFFC9D1D9) : foregroundColor,
        ),
      );
    }

    return HighlightView(
      code,
      language: normalizedLanguage,
      theme: vs2015Theme,
      padding: EdgeInsets.zero,
      textStyle: const TextStyle(
        fontFamily: AppTheme.fontFamilyMono,
        fontSize: 12.5,
        height: 1.6,
      ),
    );
  }

  Widget _buildDiffBlock(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines.length; index++)
          Container(
            color: _diffBackground(lines[index]),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamilyMono,
                      fontSize: 12.5,
                      height: 1.6,
                      color: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SelectableText(
                  lines[index],
                  contextMenuBuilder: _buildMessageActionContextMenuBuilder(
                    widget.onMessageAction,
                  ),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyMono,
                    fontSize: 12.5,
                    height: 1.6,
                    color: _diffForeground(lines[index]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _diffBackground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return const Color(0x33238B4B);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return const Color(0x33DA3633);
    }
    if (line.startsWith('@@')) {
      return const Color(0x334A4A7A);
    }
    return Colors.transparent;
  }

  Color _diffForeground(String line) {
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return const Color(0xFF7EE787);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return const Color(0xFFFF7B72);
    }
    if (line.startsWith('@@')) {
      return const Color(0xFF79C0FF);
    }
    return Colors.white;
  }
}
