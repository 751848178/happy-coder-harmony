part of 'appearance_settings_screen.dart';

const List<ColorTheme> _appearanceColorThemes = [
  ColorTheme(id: 'brand', name: '品牌色', color: AppTheme.brandColor),
  ColorTheme(id: 'blue', name: '蓝色', color: AppTheme.infoColor),
  ColorTheme(id: 'green', name: '绿色', color: AppTheme.successColor),
  ColorTheme(id: 'purple', name: '紫色', color: Color(0xFF9C27B0)),
  ColorTheme(id: 'orange', name: '橙色', color: AppTheme.warningColor),
];

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorTheme {
  const ColorTheme({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

class _ColorThemeOption extends StatelessWidget {
  const _ColorThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final ColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.color.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.color : AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
