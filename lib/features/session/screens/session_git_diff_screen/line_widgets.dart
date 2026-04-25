part of 'session_git_diff_screen.dart';

class _SessionGitFileLineTile extends StatelessWidget {
  const _SessionGitFileLineTile({
    required this.lineNumber,
    required this.content,
  });

  final int lineNumber;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$lineNumber',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              content,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.55,
                fontFamily: 'monospace',
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionGitDiffLineTile extends StatelessWidget {
  const _SessionGitDiffLineTile({
    required this.line,
  });

  final _PatchLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: patchBackgroundColor(line.type),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiffLineNumber(value: line.leftNumber),
          const SizedBox(width: 12),
          _DiffLineNumber(value: line.rightNumber),
          const SizedBox(width: 12),
          SizedBox(
            width: 14,
            child: Text(
              line.symbol,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: patchForegroundColor(line.type),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              line.content,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.55,
                fontFamily: 'monospace',
                color: patchForegroundColor(line.type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffLineNumber extends StatelessWidget {
  const _DiffLineNumber({
    required this.value,
  });

  final int? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        value?.toString() ?? '',
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
