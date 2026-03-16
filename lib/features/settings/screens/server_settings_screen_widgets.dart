part of 'server_settings_screen.dart';

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral900,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ServerOptionTile extends StatelessWidget {
  const _ServerOptionTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String value;
  final String title;
  final String subtitle;
  final String url;

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
          color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        activeColor: AppTheme.brandColor,
        selected: isSelected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
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
