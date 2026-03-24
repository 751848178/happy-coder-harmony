part of 'usage_statistics_screen.dart';

class _DailyUsageSection extends StatelessWidget {
  const _DailyUsageSection({required this.dailyUsage});

  final List<DailyUsage> dailyUsage;

  @override
  Widget build(BuildContext context) {
    if (dailyUsage.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('每日使用'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: const Text(
              '暂无可展示的每日使用数据',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
          ),
        ],
      );
    }

    final maxMessages =
        dailyUsage.map((d) => d.messages).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('每日使用'),
        const SizedBox(height: 12),
        const Text(
          '近 31 天的消息活跃度走势',
          style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _UsageChartPainter(
                data: dailyUsage,
                maxValue: maxMessages.toDouble(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppTheme.brandColor, label: '消息数'),
          ],
        ),
      ],
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  _UsageChartPainter({required this.data, required this.maxValue});

  final List<DailyUsage> data;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.brandColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = AppTheme.brandColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const horizontalPadding = 18.0;
    const topPadding = 16.0;
    const bottomPadding = 34.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - topPadding - bottomPadding;
    final stepX = chartWidth / (data.length <= 1 ? 1 : data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = horizontalPadding + i * stepX;
      final y = size.height -
          bottomPadding -
          ((data[i].messages / maxValue) * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - bottomPadding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final lastX = horizontalPadding + (data.length - 1) * stepX;
    fillPath
      ..lineTo(lastX, size.height - bottomPadding)
      ..close();
    canvas
      ..drawPath(fillPath, fillPaint)
      ..drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = AppTheme.surface
      ..strokeWidth = 2;
    for (int i = 0; i < data.length; i++) {
      final x = horizontalPadding + i * stepX;
      final y = size.height -
          bottomPadding -
          ((data[i].messages / maxValue) * chartHeight);
      canvas.drawCircle(Offset(x, y), 4, linePaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final interval = data.length > 18 ? 6 : 4;
    for (int i = 0; i < data.length; i += interval) {
      final label = '${data[i].date.month}/${data[i].date.day}';
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: AppTheme.neutral500, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          horizontalPadding + i * stepX - textPainter.width / 2,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_UsageChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
        ),
      ],
    );
  }
}
