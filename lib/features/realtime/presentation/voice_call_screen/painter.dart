part of 'voice_call_screen.dart';

class _AudioWavePainter extends CustomPainter {
  _AudioWavePainter(this.levels);

  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.shortestSide / 2 - 20;

    for (int i = 0; i < levels.length; i++) {
      final angle = (i / levels.length) * 2 * math.pi;
      final radius = maxRadius * levels[i];
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AudioWavePainter oldDelegate) {
    return oldDelegate.levels != levels;
  }
}
