part of 'usage_stats_panel.dart';

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _DetailedStatCard extends StatelessWidget {
  const _DetailedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.neutral600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.neutral500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelUsageBar extends StatelessWidget {
  const _ModelUsageBar({
    required this.modelName,
    required this.usage,
    required this.percentage,
  });

  final String modelName;
  final int usage;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final displayName = _modelDisplayName(modelName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$usage tokens (${percentage.toStringAsFixed(1)}%)',
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.neutral600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.neutral100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_modelColor(displayName)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

String _modelDisplayName(String modelName) {
  final normalized = modelName.toLowerCase();
  if (normalized.contains('claude')) return 'Claude';
  if (normalized.contains('gpt')) return 'GPT';
  if (normalized.contains('llama')) return 'Llama';
  return modelName;
}

Color _modelColor(String displayName) {
  final normalized = displayName.toLowerCase();
  if (normalized.contains('claude')) return const Color(0xFFD97757);
  if (normalized.contains('gpt')) return const Color(0xFF10A37F);
  if (normalized.contains('llama')) return const Color(0xFF6366F1);
  return AppTheme.brandColor;
}
