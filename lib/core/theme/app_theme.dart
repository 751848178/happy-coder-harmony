import 'package:flutter/material.dart';

/// 应用主题配置
///
/// 统一管理应用的颜色、字体、样式
class AppTheme {
  AppTheme._();

  // ========== 颜色定义 ==========

  /// 主品牌色
  static const Color brandColor = Color(0xFF6366F1);
  static const Color brandLight = Color(0xFF8B7FFF);
  static const Color brandDark = Color(0xFF4338CA);

  /// 成功色
  static const Color successColor = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);

  /// 警告色
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);

  /// 错误色
  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  /// 信息色
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  /// 中性色
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  /// 代码语法高亮色 (Dark 主题)
  static const Color codeBackgroundDark = Color(0xFF1E1E1E);
  static const Color codeForegroundDark = Color(0xFFD4D4D4);
  static const Color codeCommentDark = Color(0xFF6A9955);
  static const Color codeKeywordDark = Color(0xFF569CD6);
  static const Color codeStringDark = Color(0xFF98C379);
  static const Color codeNumberDark = Color(0xFFD19A66);
  static const Color codeFunctionDark = Color(0xFF61AFEF);

  /// 代码语法高亮色 (Light 主题)
  static const Color codeBackgroundLight = Color(0xFFFFFFFF);
  static const Color codeForegroundLight = Color(0xFF24292E);
  static const Color codeCommentLight = Color(0xFF6A737D);
  static const Color codeKeywordLight = Color(0xFFC586C0);
  static const Color codeStringLight = Color(0xFF6A8759);
  static const Color codeNumberLight = Color(0xFF295D99);
  static const Color codeFunctionLight = Color(0xFF07A);

  /// Diff 颜色
  static const Color diffAdded = Color(0xFF34D399);
  static const Color diffRemoved = Color(0xFFEF4444);
  static const Color diffAddedBackground = Color(0x1A343322);
  static const Color diffRemovedBackground = Color(0x33281818);

  // ========== 便捷访问属性 ==========

  /// 表面颜色（卡片背景）
  static const Color surface = Colors.white;

  /// 深色模式表面颜色
  static const Color surfaceDark = neutral800;

  /// 主文字颜色
  static const Color textPrimary = neutral900;

  /// 次要文字颜色
  static const Color textSecondary = neutral600;

  // ========== 字体定义 ==========

  static const String fontFamilyPrimary = 'IBMPlexSans';
  static const String fontFamilyMono = 'IBMPlexMono';

  // ========== 字体大小 ==========

  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 24.0;
  static const double fontSizeH1 = 32.0;

  // ========== 间距 ==========

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ========== 圆角 ==========

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;

  // ========== 阴影 ==========

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  // ========== Light Theme ==========

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: brandColor,
    scaffoldBackgroundColor: neutral50,
    cardColor: Colors.white,
    fontFamily: fontFamilyPrimary,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: fontSizeMd,
        color: neutral900,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeSm,
        color: neutral700,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: neutral800,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: brandColor,
      secondary: brandLight,
      surface: Colors.white,
      error: errorColor,
      onPrimary: Colors.white,
      onSurface: neutral900,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: neutral900,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: brandColor,
      unselectedItemColor: neutral500,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral50,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
    ),
  );

  // ========== Dark Theme ==========

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: brandLight,
    scaffoldBackgroundColor: neutral900,
    cardColor: neutral800,
    fontFamily: fontFamilyPrimary,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: fontSizeMd,
        color: neutral100,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeSm,
        color: neutral300,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: neutral100,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: brandLight,
      secondary: brandColor,
      surface: neutral800,
      error: errorColor,
      onPrimary: neutral900,
      onSurface: neutral100,
      onError: neutral100,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: neutral800,
      foregroundColor: neutral100,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neutral800,
      selectedItemColor: brandLight,
      unselectedItemColor: neutral500,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral800,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingMd,
      ),
    ),
  );

  // ========== Code Theme (Dark) ==========

  static ThemeData get codeThemeDark => darkTheme.copyWith(
    textTheme: darkTheme.textTheme.copyWith(
      bodyLarge: TextStyle(
        fontSize: fontSizeSm,
        fontFamily: fontFamilyMono,
        color: codeForegroundDark,
        height: 1.6,
      ),
    ),
    scaffoldBackgroundColor: codeBackgroundDark,
  );

  // ========== Code Theme (Light) ==========

  static ThemeData get codeThemeLight => lightTheme.copyWith(
    textTheme: lightTheme.textTheme.copyWith(
      bodyLarge: TextStyle(
        fontSize: fontSizeSm,
        fontFamily: fontFamilyMono,
        color: codeForegroundLight,
        height: 1.6,
      ),
    ),
    scaffoldBackgroundColor: codeBackgroundLight,
  );

  // ========== 辅助方法 ==========

  /// 检测系统是否为深色模式
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// 获取当前主题
  static ThemeData getTheme(BuildContext context) {
    // 这里可以从 Riverpod Provider 读取用户选择
    final isDark = isDarkMode(context);
    return isDark ? darkTheme : lightTheme;
  }

  /// 获取代码主题
  static ThemeData getCodeTheme(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? codeThemeDark : codeThemeLight;
  }
}
