part of 'new_session_flow_screen.dart';

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 210),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.brandColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brandColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = enabled ? AppTheme.brandColor : AppTheme.neutral300;
    return InkWell(
      onTap: enabled && !loading ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_upward_rounded,
                  size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
