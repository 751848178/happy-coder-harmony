part of 'session_history_list.dart';

extension _SessionHistoryListContent on SessionHistoryList {
  Widget _buildDateGroup(DateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeaders) _buildDateHeader(group),
        const SizedBox(height: 8),
        ...group.items.map((item) => _buildSessionItem(item)),
      ],
    );
  }

  Widget _buildDateHeader(DateGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        group.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral600,
        ),
      ),
    );
  }

  Widget _buildSessionItem(SessionHistoryItem item) {
    return InkWell(
      onTap: () => onItemTap(item),
      onLongPress:
          onItemLongPress == null ? null : () => onItemLongPress!(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          children: [
            _buildSessionLeading(item,
                compact: compact, showThumbnails: showThumbnails),
            const SizedBox(width: 12),
            Expanded(child: _SessionItemMeta(item: item, compact: compact)),
            _buildCompactBadges(item, compact: compact),
          ],
        ),
      ),
    );
  }
}

class _SessionItemMeta extends StatelessWidget {
  const _SessionItemMeta({
    required this.item,
    required this.compact,
  });

  final SessionHistoryItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            item.subtitle!,
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (!compact) ...[
          const SizedBox(height: 4),
          _SessionItemDetails(item: item),
        ],
      ],
    );
  }
}

class _SessionItemDetails extends StatelessWidget {
  const _SessionItemDetails({required this.item});

  final SessionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (item.machine != null) ...[
          const Icon(Icons.computer, size: 12, color: AppTheme.neutral500),
          const SizedBox(width: 4),
          Text(
            item.machine!,
            style: const TextStyle(fontSize: 11, color: AppTheme.neutral500),
          ),
          const SizedBox(width: 8),
        ],
        const Icon(Icons.access_time, size: 12, color: AppTheme.neutral500),
        const SizedBox(width: 4),
        Text(
          DateGrouper.getRelativeTime(item.createdAt),
          style: const TextStyle(fontSize: 11, color: AppTheme.neutral500),
        ),
        if (item.messageCount != null) ...[
          const SizedBox(width: 8),
          _HistoryCountBadge(
            text: '${item.messageCount}条消息',
            color: AppTheme.brandColor,
          ),
        ],
        if (item.changedLineCount != null && item.changedLineCount! > 0) ...[
          const SizedBox(width: 8),
          _HistoryCountBadge(
            text: '${item.changedLineCount}行改动',
            color: AppTheme.warningColor,
            backgroundAlpha: 0.12,
          ),
        ],
      ],
    );
  }
}
