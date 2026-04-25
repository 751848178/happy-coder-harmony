part of 'server_settings_screen.dart';

class _ServerOptionTile extends StatelessWidget {
  const _ServerOptionTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.url,
    this.isActive = false,
  });

  final String value;
  final String title;
  final String subtitle;
  final String url;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final selectedValue = RadioGroup.maybeOf<String>(context)?.groupValue;
    final isSelected = selectedValue == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.brandColor
              : isActive
                  ? AppTheme.successColor.withValues(alpha: 0.5)
                  : AppTheme.neutral200,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        activeColor: AppTheme.brandColor,
        selected: isSelected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral900,
                ),
              ),
            ),
            if (isActive) const _ServerStatusChip(label: '当前使用'),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerStatusChip extends StatelessWidget {
  const _ServerStatusChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.successColor,
        ),
      ),
    );
  }
}

class _ServerProbeSuccessBanner extends StatelessWidget {
  const _ServerProbeSuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '服务器检查通过，已确认支持终端授权接口。',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.successColor,
        ),
      ),
    );
  }
}
