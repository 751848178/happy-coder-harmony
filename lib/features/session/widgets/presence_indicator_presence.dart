part of 'presence_indicator.dart';

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({
    required this.isOnline,
    required this.size,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppTheme.successColor : AppTheme.neutral400,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _PresenceLabel extends StatelessWidget {
  const _PresenceLabel({required this.presence});

  final PresenceStatus presence;

  @override
  Widget build(BuildContext context) {
    final text = presence.isOnline
        ? '在线'
        : presence.isIdle
            ? '离线'
            : presence.status;
    final color = presence.isOnline
        ? AppTheme.successColor
        : presence.isIdle
            ? AppTheme.neutral500
            : AppTheme.brandColor;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
