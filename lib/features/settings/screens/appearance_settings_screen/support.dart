part of 'appearance_settings_screen.dart';

Widget _buildAppearanceSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.neutral600,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget _buildAppearanceFontSizePreview(
  double scale,
  String label,
  double currentScale,
) {
  final displayScale = scale * currentScale;
  return Column(
    children: [
      Text('Aa', style: TextStyle(fontSize: 14 * displayScale)),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.neutral600),
      ),
    ],
  );
}

Widget _buildAppearanceSettingItem({
  required IconData icon,
  required String title,
  String? subtitle,
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
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

void _showAppearanceComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('即将推出'),
      content: const Text('此功能正在开发中，敬请期待！'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}
