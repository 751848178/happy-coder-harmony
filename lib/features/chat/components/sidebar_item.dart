part of 'sidebar.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.badge,
    this.showNotificationDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final int? badge;
  final bool showNotificationDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Icon(icon,
                    size: 22,
                    color:
                        isActive ? AppTheme.brandColor : AppTheme.neutral600),
                if (showNotificationDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.brandColor : AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
