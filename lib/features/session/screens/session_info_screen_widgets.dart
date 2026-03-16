part of 'session_info_screen.dart';

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppTheme.brandColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }
}

class _InfoSectionHeader extends StatelessWidget {
  const _InfoSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.neutral700,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoContent extends StatelessWidget {
  const _InfoContent(this.content);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.neutral700,
        height: 1.4,
      ),
    );
  }
}
