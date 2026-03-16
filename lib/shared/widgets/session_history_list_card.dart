part of 'session_history_list.dart';

class SessionHistoryCard extends StatelessWidget {
  const SessionHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final SessionHistoryItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding:
              compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.subtitle!,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.neutral600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 12, color: AppTheme.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    DateGrouper.getRelativeTime(item.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.neutral500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
