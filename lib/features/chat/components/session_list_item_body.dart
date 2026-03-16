part of 'session_list.dart';

class _SessionListItemBody extends StatelessWidget {
  const _SessionListItemBody({
    required this.session,
    required this.stats,
  });

  final Session session;
  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    final isActive = session.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isActive) const _SessionActiveDot(),
            if (stats.messageCount > 0)
              _SessionMessageCountBadge(count: stats.messageCount),
            const Spacer(),
            Text(
              formatSessionListUpdatedAt(session.updatedAt),
              style: TextStyle(color: AppTheme.neutral500, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionItemIcon extends StatelessWidget {
  const _SessionItemIcon({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    final iconSpec = sessionListIconSpec(session.tag);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: session.active
            ? iconSpec.color.withValues(alpha: 0.2)
            : AppTheme.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconSpec.icon, color: iconSpec.color, size: 20),
    );
  }
}

class _SessionActiveDot extends StatelessWidget {
  const _SessionActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _SessionMessageCountBadge extends StatelessWidget {
  const _SessionMessageCountBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.neutral200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppTheme.neutral600,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
