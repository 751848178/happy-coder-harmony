part of 'session_files_browser_screen.dart';

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.value,
    this.valuePrefix = '',
  });

  final String label;
  final Color color;
  final int? value;
  final String valuePrefix;

  _StatusPill withValue(int nextValue) {
    return _StatusPill(
      label: label,
      color: color,
      value: nextValue,
      valuePrefix: valuePrefix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? label
        : label.isEmpty
            ? '$valuePrefix$value'
            : '$label $valuePrefix$value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
