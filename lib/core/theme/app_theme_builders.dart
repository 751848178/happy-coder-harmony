part of 'app_theme.dart';

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppTheme.brandColor,
    scaffoldBackgroundColor: AppTheme.neutral50,
    cardColor: Colors.white,
    fontFamily: AppTheme.fontFamilyPrimary,
    textTheme: TextTheme(
      bodyLarge: const TextStyle(
        fontSize: AppTheme.fontSizeMd,
        color: AppTheme.neutral900,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: AppTheme.fontSizeSm,
        color: AppTheme.neutral700,
        height: 1.5,
      ),
      labelLarge: const TextStyle(
        fontSize: AppTheme.fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppTheme.neutral800,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppTheme.brandColor,
      secondary: AppTheme.brandLight,
      surface: Colors.white,
      error: AppTheme.errorColor,
      onPrimary: Colors.white,
      onSurface: AppTheme.neutral900,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.neutral900,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.brandColor,
      unselectedItemColor: AppTheme.neutral500,
      elevation: 8,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.neutral50,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppTheme.brandLight,
    scaffoldBackgroundColor: AppTheme.neutral900,
    cardColor: AppTheme.neutral800,
    fontFamily: AppTheme.fontFamilyPrimary,
    textTheme: TextTheme(
      bodyLarge: const TextStyle(
        fontSize: AppTheme.fontSizeMd,
        color: AppTheme.neutral100,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: AppTheme.fontSizeSm,
        color: AppTheme.neutral300,
        height: 1.5,
      ),
      labelLarge: const TextStyle(
        fontSize: AppTheme.fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppTheme.neutral100,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppTheme.brandLight,
      secondary: AppTheme.brandColor,
      surface: AppTheme.neutral800,
      error: AppTheme.errorColor,
      onPrimary: AppTheme.neutral900,
      onSurface: AppTheme.neutral100,
      onError: AppTheme.neutral100,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.neutral800,
      foregroundColor: AppTheme.neutral100,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppTheme.neutral800,
      selectedItemColor: AppTheme.brandLight,
      unselectedItemColor: AppTheme.neutral500,
      elevation: 8,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.neutral800,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
    ),
  );
}

ThemeData _buildCodeThemeDark() {
  return AppTheme.darkTheme.copyWith(
    textTheme: AppTheme.darkTheme.textTheme.copyWith(
      bodyLarge: const TextStyle(
        fontSize: AppTheme.fontSizeSm,
        fontFamily: AppTheme.fontFamilyMono,
        color: AppTheme.codeForegroundDark,
        height: 1.6,
      ),
    ),
    scaffoldBackgroundColor: AppTheme.codeBackgroundDark,
  );
}

ThemeData _buildCodeThemeLight() {
  return AppTheme.lightTheme.copyWith(
    textTheme: AppTheme.lightTheme.textTheme.copyWith(
      bodyLarge: const TextStyle(
        fontSize: AppTheme.fontSizeSm,
        fontFamily: AppTheme.fontFamilyMono,
        color: AppTheme.codeForegroundLight,
        height: 1.6,
      ),
    ),
    scaffoldBackgroundColor: AppTheme.codeBackgroundLight,
  );
}

bool _isDarkMode(BuildContext context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark;
}

ThemeData _getTheme(BuildContext context) {
  return _isDarkMode(context) ? AppTheme.darkTheme : AppTheme.lightTheme;
}

ThemeData _getCodeTheme(BuildContext context) {
  return _isDarkMode(context)
      ? AppTheme.codeThemeDark
      : AppTheme.codeThemeLight;
}
