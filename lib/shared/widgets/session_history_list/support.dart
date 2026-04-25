part of 'session_history_list.dart';

extension _SessionHistoryListSupport on SessionHistoryList {
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            const Text(
              '暂无历史记录',
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionLeading(
    SessionHistoryItem item, {
    required bool compact,
    required bool showThumbnails,
  }) {
    if (showThumbnails && item.thumbnail != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.thumbnail!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: _sessionTypeColor(item.type).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _sessionTypeIcon(item.type),
        color: _sessionTypeColor(item.type),
        size: compact ? 20 : 24,
      ),
    );
  }

  Widget _buildCompactBadges(SessionHistoryItem item, {required bool compact}) {
    if (!compact) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.messageCount != null) ...[
          const SizedBox(width: 12),
          _HistoryCountBadge(
              text: '${item.messageCount}条', color: AppTheme.brandColor),
        ],
        if (item.changedLineCount != null && item.changedLineCount! > 0) ...[
          const SizedBox(width: 8),
          _HistoryCountBadge(
            text: '${item.changedLineCount}行',
            color: AppTheme.warningColor,
            backgroundAlpha: 0.12,
          ),
        ],
      ],
    );
  }
}

class _HistoryCountBadge extends StatelessWidget {
  const _HistoryCountBadge({
    required this.text,
    required this.color,
    this.backgroundAlpha = 0.1,
  });

  final String text;
  final Color color;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData _sessionTypeIcon(String? type) {
  return switch (type?.toLowerCase()) {
    'code' => Icons.code,
    'chat' => Icons.chat_bubble_outline,
    'writing' => Icons.edit_note_outlined,
    'debug' => Icons.bug_report_outlined,
    'review' => Icons.rate_review_outlined,
    'translate' => Icons.translate,
    _ => Icons.chat,
  };
}

Color _sessionTypeColor(String? type) {
  return switch (type?.toLowerCase()) {
    'code' => const Color(0xFF6366F1),
    'chat' => const Color(0xFF10B981),
    'writing' => const Color(0xFFF59E0B),
    'debug' => const Color(0xFFEF4444),
    'review' => const Color(0xFF8B5CF6),
    'translate' => const Color(0xFFEC4899),
    _ => AppTheme.brandColor,
  };
}
