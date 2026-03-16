part of 'avatar_styles.dart';

class MinimalistAvatarStyle {
  const MinimalistAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return _buildAvatarShell(
      size: size,
      decoration: getDecoration(color, size),
      child: child ??
          Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
    );
  }
}

class GlassAvatarStyle {
  const GlassAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.4),
        ],
      ),
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return _buildAvatarShell(
      size: size,
      decoration: getDecoration(color, size),
      child: child ??
          Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
    );
  }
}

class OutlineAvatarStyle {
  const OutlineAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return _buildAvatarShell(
      size: size,
      decoration: getDecoration(color, size),
      child: child ??
          Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
    );
  }
}
