part of 'sessions_screen.dart';

class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SessionThinkingBadge extends StatelessWidget {
  const _SessionThinkingBadge({
    this.since,
  });

  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final duration = since == null ? null : DateTime.now().difference(since!);
    final label = duration == null || duration.inSeconds < 1
        ? 'AI 思考中'
        : duration.inMinutes < 1
            ? 'AI 思考 ${duration.inSeconds}s'
            : 'AI 思考 ${duration.inMinutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.brandColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  const _SessionBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
