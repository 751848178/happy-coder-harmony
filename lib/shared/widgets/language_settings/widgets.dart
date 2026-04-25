part of 'language_settings.dart';

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final AppLocale locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(locale.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.brandColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locale.englishName,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.neutral600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.brandColor),
          ],
        ),
      ),
    );
  }
}

class QuickLanguageSelector extends StatelessWidget {
  const QuickLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final AppLanguage? selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLocale = selectedLanguage != null
        ? BuiltInLocales.byLanguage(selectedLanguage!)
        : null;
    return DropdownButtonFormField<AppLocale>(
      initialValue: selectedLocale,
      decoration:
          const InputDecoration(labelText: '语言', border: OutlineInputBorder()),
      items: BuiltInLocales.all.map((locale) {
        return DropdownMenuItem<AppLocale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(locale.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Text(locale.nativeName),
            ],
          ),
        );
      }).toList(),
      onChanged: (locale) {
        if (locale != null) {
          onLanguageChanged(locale.language);
        }
      },
    );
  }
}
