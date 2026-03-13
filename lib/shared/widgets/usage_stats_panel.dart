import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Usage period
enum UsagePeriod {
  today,
  week,
  month,
  year,
}

/// Usage statistics model
class UsageStats {
  final int totalMessages;
  final int totalTokens;
  final int totalSessions;
  final int codeGenerated;
  final int filesEdited;
  final double hoursSpent;
  final Map<String, int> modelUsage;

  const UsageStats({
    required this.totalMessages,
    required this.totalTokens,
    required this.totalSessions,
    this.codeGenerated = 0,
    this.filesEdited = 0,
    this.hoursSpent = 0,
    this.modelUsage = const {},
  });

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
  final Function(UsagePeriod)? onPeriodChange;
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

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.bar_chart,
          color: AppTheme.brandColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        const Text(
          '使用统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (onPeriodChange != null)
          _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<UsagePeriod>(
      segments: const [
        ButtonSegment(
          value: UsagePeriod.today,
          label: Text('今天'),
        ),
        ButtonSegment(
          value: UsagePeriod.week,
          label: Text('本周'),
        ),
        ButtonSegment(
          value: UsagePeriod.month,
          label: Text('本月'),
        ),
      ],
      selected: {period},
      onSelectionChanged: (Set<UsagePeriod> newSelection) {
        onPeriodChange?.call(newSelection.first);
      },
    );
  }

  Widget _buildMainMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _StatCard(
              icon: Icons.chat_bubble_outline,
              label: '消息',
              value: _formatNumber(stats.totalMessages),
              color: AppTheme.brandColor,
            ),
            _StatCard(
              icon: Icons.psychology,
              label: 'Tokens',
              value: _formatNumber(stats.totalTokens),
              color: AppTheme.infoColor,
            ),
            _StatCard(
              icon: Icons.history,
              label: '会话',
              value: _formatNumber(stats.totalSessions),
              color: AppTheme.successColor,
            ),
            _StatCard(
              icon: Icons.timer_outlined,
              label: '使用时长',
              value: _formatHours(stats.hoursSpent),
              color: AppTheme.warningColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '详细指标',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DetailedStatCard(
                icon: Icons.code,
                label: '代码生成',
                value: _formatNumber(stats.codeGenerated),
                unit: '行',
                color: AppTheme.brandColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailedStatCard(
                icon: Icons.edit_document,
                label: '文件编辑',
                value: _formatNumber(stats.filesEdited),
                unit: '个',
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelUsage() {
    final models = stats.modelUsage.entries.toList();
    final totalUsage = models.fold<num>(0, (sum, e) => sum + e.value).toInt();

    if (models.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模型使用分布',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...models.map((entry) {
          final percentage = totalUsage > 0 ? (entry.value.toDouble() / totalUsage * 100) : 0.0;
          return _ModelUsageBar(
            modelName: entry.key,
            usage: entry.value,
            percentage: percentage,
          );
        }).toList(),
      ],
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _formatHours(double hours) {
    if (hours >= 1) {
      return '${hours.toStringAsFixed(1)}h';
    }
    return '${(hours * 60).toStringAsFixed(0)}m';
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed stat card widget
class _DetailedStatCard extends StatelessWidget {
  const _DetailedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Model usage bar widget
class _ModelUsageBar extends StatelessWidget {
  const _ModelUsageBar({
    required this.modelName,
    required this.usage,
    required this.percentage,
  });

  final String modelName;
  final int usage;
  final double percentage;

  String get _displayName {
    if (modelName.toLowerCase().contains('claude')) {
      return 'Claude';
    } else if (modelName.toLowerCase().contains('gpt')) {
      return 'GPT';
    } else if (modelName.toLowerCase().contains('llama')) {
      return 'Llama';
    }
    return modelName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${usage.toString()} tokens (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.neutral100,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getModelColor(),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getModelColor() {
    final name = _displayName.toLowerCase();
    if (name.contains('claude')) {
      return const Color(0xFFD97757); // Claude orange
    } else if (name.contains('gpt')) {
      return const Color(0xFF10A37F); // OpenAI green
    } else if (name.contains('llama')) {
      return const Color(0xFF6366F1); // Indigo
    }
    return AppTheme.brandColor;
  }
}

/// Usage summary widget
class UsageSummaryWidget extends StatelessWidget {
  const UsageSummaryWidget({
    super.key,
    this.onViewDetails,
    this.period = UsagePeriod.month,
  });

  final VoidCallback? onViewDetails;
  final UsagePeriod period;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandColor,
                      AppTheme.brandColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月使用统计',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '查看详细的使用数据和模型分布',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppTheme.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick stats widget
class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({
    super.key,
    required this.stats,
    this.onTap,
  });

  final UsageStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStatItem(
                icon: Icons.send,
                label: '消息',
                value: _formatNumber(stats.totalMessages),
              ),
              _QuickStatItem(
                icon: Icons.psychology,
                label: 'Tokens',
                value: _formatNumber(stats.totalTokens),
              ),
              _QuickStatItem(
                icon: Icons.timer,
                label: '时长',
                value: _formatHours(stats.hoursSpent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _formatHours(double hours) {
    if (hours >= 1) {
      return '${hours.toStringAsFixed(1)}h';
    }
    return '${(hours * 60).toStringAsFixed(0)}m';
  }
}

/// Quick stat item widget
class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.brandColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.neutral500,
          ),
        ),
      ],
    );
  }
}
