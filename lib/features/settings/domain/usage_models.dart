import 'package:json_annotation/json_annotation.dart';

part 'usage_models.g.dart';

/// Usage Statistics Model
@JsonSerializable()
class UsageStatistics {
  final int totalSessions;
  final int totalMessages;
  final int totalTokens;
  final double totalCost;
  final int totalFilesAccessed;
  final int totalToolsUsed;
  final DateTime firstSessionDate;
  final DateTime lastSessionDate;
  final int daysActive;
  final List<DailyUsage> dailyUsage;
  final Map<String, int> toolsUsage;
  final Map<String, int> modelUsage;

  const UsageStatistics({
    required this.totalSessions,
    required this.totalMessages,
    required this.totalTokens,
    required this.totalCost,
    required this.totalFilesAccessed,
    required this.totalToolsUsed,
    required this.firstSessionDate,
    required this.lastSessionDate,
    required this.daysActive,
    required this.dailyUsage,
    required this.toolsUsage,
    required this.modelUsage,
  });

  factory UsageStatistics.fromJson(Map<String, dynamic> json) =>
      _$UsageStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$UsageStatisticsToJson(this);
}

/// Daily Usage Entry
@JsonSerializable()
class DailyUsage {
  final DateTime date;
  final int messages;
  final int tokens;
  final int sessions;

  const DailyUsage({
    required this.date,
    required this.messages,
    required this.tokens,
    required this.sessions,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) =>
      _$DailyUsageFromJson(json);

  Map<String, dynamic> toJson() => _$DailyUsageToJson(this);
}

/// Language Setting
@JsonSerializable()
class LanguageSetting {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageSetting({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  factory LanguageSetting.fromJson(Map<String, dynamic> json) =>
      _$LanguageSettingFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageSettingToJson(this);
}

/// Available Languages
class AppLanguages {
  static const List<LanguageSetting> available = [
    LanguageSetting(
      code: 'zh',
      name: 'Chinese',
      nativeName: '简体中文',
      flag: '🇨🇳',
    ),
    LanguageSetting(
      code: 'zh-TW',
      name: 'Traditional Chinese',
      nativeName: '繁體中文',
      flag: '🇹🇼',
    ),
    LanguageSetting(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageSetting(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    LanguageSetting(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    LanguageSetting(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageSetting(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageSetting(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
  ];

  static LanguageSetting? getByCode(String code) {
    try {
      return available.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return available.first;
    }
  }
}
