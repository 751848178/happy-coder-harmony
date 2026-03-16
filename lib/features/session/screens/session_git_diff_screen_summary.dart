part of 'session_git_diff_screen.dart';

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DiffSummaryBar extends StatelessWidget {
  const _DiffSummaryBar({required this.file});

  final SessionGitFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryTag(
            label: _statusLabel(file.status),
            background: _statusColor(file.status).withValues(alpha: 0.16),
            foreground: _statusColor(file.status),
          ),
          if (file.addedLines > 0)
            const _SummaryTag(
              label: '新增行',
              background: Color(0x22052E16),
              foreground: Color(0xFF86EFAC),
              valuePrefix: '+',
            ).withValue(file.addedLines),
          if (file.removedLines > 0)
            const _SummaryTag(
              label: '删除行',
              background: Color(0x223F0D12),
              foreground: Color(0xFFFDA4AF),
              valuePrefix: '-',
            ).withValue(file.removedLines),
          if (file.previousPath != null && file.previousPath!.isNotEmpty)
            _SummaryTag(
              label: '来自 ${file.previousPath}',
              background: const Color(0xFF1F2937),
              foreground: const Color(0xFFCBD5E1),
            ),
        ],
      ),
    );
  }

  static String _statusLabel(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return '新增';
      case SessionGitFileStatus.deleted:
        return '删除';
      case SessionGitFileStatus.renamed:
        return '重命名';
      case SessionGitFileStatus.untracked:
        return '未跟踪';
      case SessionGitFileStatus.modified:
        return '修改';
    }
  }

  static Color _statusColor(SessionGitFileStatus status) {
    switch (status) {
      case SessionGitFileStatus.added:
        return const Color(0xFF22C55E);
      case SessionGitFileStatus.deleted:
        return const Color(0xFFEF4444);
      case SessionGitFileStatus.renamed:
        return const Color(0xFF3B82F6);
      case SessionGitFileStatus.untracked:
        return const Color(0xFF94A3B8);
      case SessionGitFileStatus.modified:
        return const Color(0xFFF59E0B);
    }
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({
    required this.label,
    required this.background,
    required this.foreground,
    this.value,
    this.valuePrefix = '',
  });

  final String label;
  final Color background;
  final Color foreground;
  final int? value;
  final String valuePrefix;

  _SummaryTag withValue(int nextValue) {
    return _SummaryTag(
      label: label,
      background: background,
      foreground: foreground,
      value: nextValue,
      valuePrefix: valuePrefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value == null ? label : '$label $valuePrefix$value',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
