part of 'user_profile_screen.dart';

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({
    required this.child,
    this.title,
    this.icon,
  });

  final Widget child;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: title == null ? child : _buildTitledCard(),
    );
  }

  Widget _buildTitledCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.brandColor, size: 20),
            const SizedBox(width: 12),
            Text(
              title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
