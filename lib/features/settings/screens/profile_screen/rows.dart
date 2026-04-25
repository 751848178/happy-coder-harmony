part of 'profile_screen.dart';

Widget _buildProfileInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMd,
      vertical: AppTheme.spacingSm,
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.neutral600),
        const SizedBox(width: AppTheme.spacingMd),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.neutral900,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildProfileStatRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMd,
      vertical: AppTheme.spacingSm,
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.brandColor),
        const SizedBox(width: AppTheme.spacingMd),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.neutral900,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProfileDivider() {
  return const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
    child: Divider(height: 1),
  );
}

Widget _buildProfileQuickAction({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return Container(
    margin:
        const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}
