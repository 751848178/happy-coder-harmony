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
    required this.session,
    required this.isActive,
    required this.isThinking,
  });

  final Session session;
  final bool isActive;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    return SessionAgentAvatar(
      session: session,
      isActive: isActive,
      isThinking: isThinking,
    );
  }
}
