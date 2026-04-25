part of 'home_screen.dart';

class _HomeMachineDrawerTile extends StatelessWidget {
  const _HomeMachineDrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.selected,
    required this.onTap,
    this.isOnline = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final int count;
  final bool selected;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppTheme.brandColor.withValues(alpha: 0.08)
        : Colors.transparent;
    final borderColor = selected
        ? AppTheme.brandColor.withValues(alpha: 0.18)
        : AppTheme.neutral200;
    final iconBackground = selected
        ? AppTheme.brandColor.withValues(alpha: 0.14)
        : AppTheme.neutral100;
    final iconColor = selected ? AppTheme.brandColor : AppTheme.neutral500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildIcon(iconBackground, iconColor),
                const SizedBox(width: 12),
                Expanded(child: _buildTexts()),
                const SizedBox(width: 12),
                _buildCountChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color iconBackground, Color iconColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icon, size: 22, color: iconColor)),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppTheme.brandColor.withValues(alpha: 0.14)
                        : iconBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
        ),
      ],
    );
  }

  Widget _buildCountChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.brandColor.withValues(alpha: 0.14)
            : AppTheme.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? AppTheme.brandColor : AppTheme.neutral700,
        ),
      ),
    );
  }
}
