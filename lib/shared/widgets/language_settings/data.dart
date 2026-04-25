part of 'language_settings.dart';

enum AppLanguage {
  zhCN,
  zhTW,
  enUS,
  jaJP,
  koKR,
  frFR,
  deDE,
  esES,
  ptBR,
  ruRU,
}

class AppLocale {
  const AppLocale({
    required this.language,
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });

  final AppLanguage language;
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;

  String get displayName => nativeName;
}

class BuiltInLocales {
  static const all = [
    AppLocale(
        language: AppLanguage.zhCN,
        code: 'zh-CN',
        nativeName: '简体中文',
        englishName: 'Simplified Chinese',
        flag: '🇨🇳'),
    AppLocale(
        language: AppLanguage.zhTW,
        code: 'zh-TW',
        nativeName: '繁體中文',
        englishName: 'Traditional Chinese',
        flag: '🇹🇼'),
    AppLocale(
        language: AppLanguage.enUS,
        code: 'en-US',
        nativeName: 'English',
        englishName: 'English (US)',
        flag: '🇺🇸'),
    AppLocale(
        language: AppLanguage.jaJP,
        code: 'ja-JP',
        nativeName: '日本語',
        englishName: 'Japanese',
        flag: '🇯🇵'),
    AppLocale(
        language: AppLanguage.koKR,
        code: 'ko-KR',
        nativeName: '한국어',
        englishName: 'Korean',
        flag: '🇰🇷'),
    AppLocale(
        language: AppLanguage.frFR,
        code: 'fr-FR',
        nativeName: 'Français',
        englishName: 'French',
        flag: '🇫🇷'),
    AppLocale(
        language: AppLanguage.deDE,
        code: 'de-DE',
        nativeName: 'Deutsch',
        englishName: 'German',
        flag: '🇩🇪'),
    AppLocale(
        language: AppLanguage.esES,
        code: 'es-ES',
        nativeName: 'Español',
        englishName: 'Spanish',
        flag: '🇪🇸'),
    AppLocale(
        language: AppLanguage.ptBR,
        code: 'pt-BR',
        nativeName: 'Português',
        englishName: 'Portuguese (Brazil)',
        flag: '🇧🇷'),
    AppLocale(
        language: AppLanguage.ruRU,
        code: 'ru-RU',
        nativeName: 'Русский',
        englishName: 'Russian',
        flag: '🇷🇺'),
  ];

  static AppLocale? byLanguage(AppLanguage language) {
    for (final locale in all) {
      if (locale.language == language) {
        return locale;
      }
    }
    return null;
  }

  static AppLocale? byCode(String code) {
    for (final locale in all) {
      if (locale.code == code) {
        return locale;
      }
    }
    return null;
  }
}

class LanguageModel {
  const LanguageModel({
    required this.language,
    this.lastUpdated,
  });

  final AppLanguage language;
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      language: AppLanguage.values.firstWhere(
        (entry) => entry.name == json['language'],
        orElse: () => AppLanguage.zhCN,
      ),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  LanguageModel copyWith({
    AppLanguage? language,
    DateTime? lastUpdated,
  }) {
    return LanguageModel(
      language: language ?? this.language,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
