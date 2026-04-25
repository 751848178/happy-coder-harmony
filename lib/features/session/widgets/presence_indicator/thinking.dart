part of 'presence_indicator.dart';

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator({
    required this.size,
    this.since,
  });

  final double size;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
          ),
        ),
        if (since != null) ...[
          const SizedBox(width: 6),
          _ThinkingDuration(since: since!),
        ],
      ],
    );
  }
}

class _ThinkingDuration extends StatefulWidget {
  const _ThinkingDuration({required this.since});

  final DateTime since;

  @override
  State<_ThinkingDuration> createState() => _ThinkingDurationState();
}

class _ThinkingDurationState extends State<_ThinkingDuration> {
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.since);
  }

  @override
  void didUpdateWidget(_ThinkingDuration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.since != widget.since) {
      _duration = DateTime.now().difference(widget.since);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        return Text(
          _formatDuration(_duration),
          style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
        );
      },
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration.inSeconds < 1) return '思考中...';
  if (duration.inSeconds < 60) return '思考 ${duration.inSeconds}s';
  if (duration.inMinutes < 60) {
    return '思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
  return '思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
}
