part of 'sessions_screen.dart';

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionLeadingIcon extends StatelessWidget {
  const _SessionLeadingIcon({
    required this.isActive,
    required this.isThinking,
  });

  final bool isActive;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                AppTheme.brandColor.withValues(alpha: isThinking ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: isActive || isThinking
                ? AppTheme.brandColor
                : AppTheme.neutral500,
          ),
        ),
        if (isThinking)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.brandColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
