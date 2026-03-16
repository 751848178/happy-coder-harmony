part of 'session_screen.dart';

class _TurnMetaChip extends StatelessWidget {
  const _TurnMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.neutral700,
        ),
      ),
    );
  }
}

class _ScrollActionButton extends StatelessWidget {
  const _ScrollActionButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                size: 20,
                color: enabled ? AppTheme.textPrimary : AppTheme.neutral400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
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

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.neutral300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.neutral700),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

