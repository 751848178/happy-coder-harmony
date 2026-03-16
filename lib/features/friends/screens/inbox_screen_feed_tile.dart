part of 'inbox_screen.dart';

class _InboxFeedTile extends StatelessWidget {
  const _InboxFeedTile({
    required this.item,
    this.onTap,
  });

  final InboxItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = inboxFeedIconColor(item);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(inboxFeedIcon(item), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  if ((item.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatInboxRelativeTime(item.createdAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
