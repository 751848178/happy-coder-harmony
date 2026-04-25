import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

part 'cards.dart';
part 'panel.dart';
part 'summary.dart';

/// Usage period
enum UsagePeriod {
  today,
  week,
  month,
  year,
}

/// Usage statistics model
class UsageStats {
  const UsageStats({
    required this.totalMessages,
    required this.totalTokens,
    required this.totalSessions,
    this.codeGenerated = 0,
    this.filesEdited = 0,
    this.hoursSpent = 0,
    this.modelUsage = const {},
  });

  final int totalMessages;
  final int totalTokens;
  final int totalSessions;
  final int codeGenerated;
  final int filesEdited;
  final double hoursSpent;
  final Map<String, int> modelUsage;

  UsageStats copyWith({
    int? totalMessages,
    int? totalTokens,
    int? totalSessions,
    int? codeGenerated,
    int? filesEdited,
    double? hoursSpent,
    Map<String, int>? modelUsage,
  }) {
    return UsageStats(
      totalMessages: totalMessages ?? this.totalMessages,
      totalTokens: totalTokens ?? this.totalTokens,
      totalSessions: totalSessions ?? this.totalSessions,
      codeGenerated: codeGenerated ?? this.codeGenerated,
      filesEdited: filesEdited ?? this.filesEdited,
      hoursSpent: hoursSpent ?? this.hoursSpent,
      modelUsage: modelUsage ?? this.modelUsage,
    );
  }
}

/// Usage Stats Panel Widget
///
/// Displays usage statistics and metrics
class UsageStatsPanel extends StatelessWidget {
  const UsageStatsPanel({
    super.key,
    required this.stats,
    this.period = UsagePeriod.week,
    this.onPeriodChange,
    this.compact = false,
  });

  final UsageStats stats;
  final UsagePeriod period;
  final ValueChanged<UsagePeriod>? onPeriodChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMainMetrics(),
            const SizedBox(height: 20),
            if (!compact) ...[
              _buildDetailedMetrics(),
              const SizedBox(height: 20),
              _buildModelUsage(),
            ],
          ],
        ),
      ),
    );
  }
}
