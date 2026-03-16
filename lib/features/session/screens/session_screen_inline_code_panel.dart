part of 'session_screen.dart';

class _InlineCodePanel extends StatefulWidget {
  const _InlineCodePanel({
    required this.code,
    required this.language,
    required this.isUser,
    this.collapsedLines = 8,
  });

  final String code;
  final String language;
  final bool isUser;
  final int collapsedLines;

  @override
  State<_InlineCodePanel> createState() => _InlineCodePanelState();
}

class _InlineCodePanelState extends State<_InlineCodePanel>
    with AutomaticKeepAliveClientMixin<_InlineCodePanel> {
  bool _expanded = false;

  @override
  bool get wantKeepAlive => _expanded;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final normalizedCode = widget.code.trimRight();
    final lines = normalizedCode.split('\n');
    final shouldCollapse =
        lines.length > widget.collapsedLines || widget.code.length > 320;
    final visibleCode = !_expanded && shouldCollapse
        ? lines.take(widget.collapsedLines).join('\n')
        : normalizedCode;
    final visibleLines = visibleCode.split('\n');
    final isDiff = _isDiffLanguage(widget.language);
    final isTerminal = _isTerminalLanguage(widget.language);
    final backgroundColor = widget.isUser
        ? const Color(0xFF1F2937)
        : isTerminal
            ? const Color(0xFF0D1117)
            : const Color(0xFF1E1E1E);
    final foregroundColor = Colors.white;
    final borderColor = widget.isUser
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF30363D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTerminal ? Icons.terminal_rounded : Icons.code_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                _languageLabel(widget.language),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamilyMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${lines.length} 行',
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamilyMono,
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: normalizedCode),
                  );
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('代码已复制'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '复制',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              if (shouldCollapse) const SizedBox(width: 8),
              if (shouldCollapse)
                InkWell(
                  onTap: () {
                    setState(() => _expanded = !_expanded);
                    updateKeepAlive();
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      _expanded ? '收起' : '展开',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58A6FF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
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
                            color: Colors.white10,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _buildCodeBody(
                          visibleCode,
                          foregroundColor: foregroundColor,
                          isTerminal: isTerminal,
                        ),
                      ],
                    ),
            ),
          ),
          if (shouldCollapse && !_expanded) ...[
            const SizedBox(height: 6),
            Text(
              '还有 ${lines.length - widget.collapsedLines} 行',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

}
