// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageStatistics _$UsageStatisticsFromJson(Map<String, dynamic> json) =>
    UsageStatistics(
      totalSessions: (json['totalSessions'] as num).toInt(),
      totalMessages: (json['totalMessages'] as num).toInt(),
      totalTokens: (json['totalTokens'] as num).toInt(),
      totalCost: (json['totalCost'] as num).toDouble(),
      totalFilesAccessed: (json['totalFilesAccessed'] as num).toInt(),
      totalToolsUsed: (json['totalToolsUsed'] as num).toInt(),
      firstSessionDate: DateTime.parse(json['firstSessionDate'] as String),
      lastSessionDate: DateTime.parse(json['lastSessionDate'] as String),
      daysActive: (json['daysActive'] as num).toInt(),
      dailyUsage: (json['dailyUsage'] as List<dynamic>)
          .map((e) => DailyUsage.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolsUsage: Map<String, int>.from(json['toolsUsage'] as Map),
      modelUsage: Map<String, int>.from(json['modelUsage'] as Map),
    );

Map<String, dynamic> _$UsageStatisticsToJson(UsageStatistics instance) =>
    <String, dynamic>{
      'totalSessions': instance.totalSessions,
      'totalMessages': instance.totalMessages,
      'totalTokens': instance.totalTokens,
      'totalCost': instance.totalCost,
      'totalFilesAccessed': instance.totalFilesAccessed,
      'totalToolsUsed': instance.totalToolsUsed,
      'firstSessionDate': instance.firstSessionDate.toIso8601String(),
      'lastSessionDate': instance.lastSessionDate.toIso8601String(),
      'daysActive': instance.daysActive,
      'dailyUsage': instance.dailyUsage,
      'toolsUsage': instance.toolsUsage,
      'modelUsage': instance.modelUsage,
    };

DailyUsage _$DailyUsageFromJson(Map<String, dynamic> json) => DailyUsage(
      date: DateTime.parse(json['date'] as String),
      messages: (json['messages'] as num).toInt(),
      tokens: (json['tokens'] as num).toInt(),
      sessions: (json['sessions'] as num).toInt(),
    );

Map<String, dynamic> _$DailyUsageToJson(DailyUsage instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'messages': instance.messages,
      'tokens': instance.tokens,
      'sessions': instance.sessions,
    };

LanguageSetting _$LanguageSettingFromJson(Map<String, dynamic> json) =>
    LanguageSetting(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['nativeName'] as String,
      flag: json['flag'] as String,
    );

Map<String, dynamic> _$LanguageSettingToJson(LanguageSetting instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'nativeName': instance.nativeName,
      'flag': instance.flag,
    };
