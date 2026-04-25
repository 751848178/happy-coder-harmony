part of 'appearance_settings_screen.dart';

Widget _buildAppearanceThemeModeSelector({
  required bool isDarkMode,
  required ValueChanged<bool> onTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ThemeModeOption(
            icon: Icons.light_mode_outlined,
            title: '浅色',
            isSelected: !isDarkMode,
            onTap: () => onTap(false),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _ThemeModeOption(
            icon: Icons.dark_mode_outlined,
            title: '深色',
            isSelected: isDarkMode,
            onTap: () => onTap(true),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAppearanceColorThemeSelector({
  required List<ColorTheme> colorThemes,
  required String selectedTheme,
  required ValueChanged<String> onTap,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
    ),
    child: Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: colorThemes
          .map(
            (theme) => _ColorThemeOption(
              theme: theme,
              isSelected: selectedTheme == theme.id,
              onTap: () => onTap(theme.id),
            ),
          )
          .toList(),
    ),
  );
}

Widget _buildAppearanceFontSizeSlider({
  required double fontSize,
  required ValueChanged<double> onChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '字体大小',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(fontSize * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.brandColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Slider(
          value: fontSize,
          min: 0.75,
          max: 1.5,
          divisions: 6,
          activeColor: AppTheme.brandColor,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAppearanceFontSizePreview(0.75, '小', fontSize),
            _buildAppearanceFontSizePreview(1.0, '标准', fontSize),
            _buildAppearanceFontSizePreview(1.25, '大', fontSize),
            _buildAppearanceFontSizePreview(1.5, '特大', fontSize),
          ],
        ),
      ],
    ),
  );
}
