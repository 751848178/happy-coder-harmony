part of 'avatar_styles.dart';

class GradientAvatarStyle {
  const GradientAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withValues(alpha: 0.7)],
      ),
      shape: BoxShape.circle,
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

class PixelatedAvatarStyle {
  const PixelatedAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black, width: 2),
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
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              letterSpacing: size * 0.02,
            ),
          ),
    );
  }
}

class BrutalistAvatarStyle {
  const BrutalistAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.black, width: 3),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(4, 4),
          blurRadius: 0,
        ),
      ],
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
    );
  }
}

Widget _buildAvatarShell({
  required double size,
  required BoxDecoration decoration,
  required Widget child,
}) {
  return Container(
    width: size,
    height: size,
    decoration: decoration,
    child: Center(child: child),
  );
}
