import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/usage_models.dart';

/// Usage Statistics Screen
///
/// 使用统计页面
class UsageStatisticsScreen extends ConsumerStatefulWidget {
  const UsageStatisticsScreen({super.key});

  @override
  ConsumerState<UsageStatisticsScreen> createState() =>
      _UsageStatisticsScreenState();
}

class _UsageStatisticsScreenState extends ConsumerState<UsageStatisticsScreen> {
  bool _isLoading = true;
  UsageStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    // TODO: Load from API
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
      _statistics = _getMockStatistics();
    });
  }

  UsageStatistics _getMockStatistics() {
    final now = DateTime.now();
    return UsageStatistics(
      totalSessions: 42,
      totalMessages: 1234,
      totalTokens: 567890,
      totalCost: 12.34,
      totalFilesAccessed: 89,
      totalToolsUsed: 156,
      firstSessionDate: DateTime(2026, 2, 1),
      lastSessionDate: now,
      daysActive: 28,
      dailyUsage: _generateDailyUsage(),
      toolsUsage: {
        'Bash': 45,
        'Edit': 32,
        'Write': 28,
        'Glob': 15,
        'Grep': 12,
        'Read': 24,
      },
      modelUsage: {
        'Claude 3.5 Sonnet': 56,
        'Claude 3 Opus': 32,
        'Claude 3 Haiku': 18,
      },
    );
  }

  List<DailyUsage> _generateDailyUsage() {
    final now = DateTime.now();
    final result = <DailyUsage>[];
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final day = date.weekday;
      final messages = day >= 1 && day <= 5 ? (10 + (i % 20)) : (5 + (i % 10));
      final tokens = messages * (100 + (i % 50));
      result.add(DailyUsage(
        date: date,
        messages: messages,
        tokens: tokens,
        sessions: (messages / 5).ceil(),
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('使用统计'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandColor),
            )
          : _statistics != null
              ? _StatisticsContent(statistics: _statistics!)
              : const Center(
                  child: Text('暂无统计数据'),
                ),
    );
  }
}

/// Statistics Content
class _StatisticsContent extends StatelessWidget {
  final UsageStatistics statistics;

  const _StatisticsContent({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _SummarySection(statistics: statistics),
          const SizedBox(height: 24),

          // Daily Usage Chart
          _DailyUsageSection(dailyUsage: statistics.dailyUsage),
          const SizedBox(height: 24),

          // Tools Usage
          _ToolsUsageSection(toolsUsage: statistics.toolsUsage),
          const SizedBox(height: 24),

          // Model Usage
          _ModelUsageSection(modelUsage: statistics.modelUsage),
          const SizedBox(height: 24),

          // Activity Info
          _ActivityInfoSection(statistics: statistics),
        ],
      ),
    );
  }
}

/// Summary Section
class _SummarySection extends StatelessWidget {
  final UsageStatistics statistics;

  const _SummarySection({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('概览'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
            final cards = [
              _StatCard(
                icon: Icons.message_outlined,
                label: '消息总数',
                value: statistics.totalMessages.toString(),
                color: AppTheme.brandColor,
              ),
              _StatCard(
                icon: Icons.psychology_outlined,
                label: 'Token 总量',
                value: _formatNumber(statistics.totalTokens),
                color: Colors.purple,
              ),
              _StatCard(
                icon: Icons.attach_money,
                label: '累计花费',
                value: '\$${statistics.totalCost.toStringAsFixed(2)}',
                color: Colors.green,
              ),
              _StatCard(
                icon: Icons.folder_open_outlined,
                label: '访问文件数',
                value: statistics.totalFilesAccessed.toString(),
                color: Colors.orange,
              ),
              _StatCard(
                icon: Icons.calendar_today_outlined,
                label: '活跃天数',
                value: '${statistics.daysActive} 天',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.build_circle_outlined,
                label: '工具调用数',
                value: statistics.totalToolsUsed.toString(),
                color: Colors.teal,
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 142,
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
      ],
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

/// Stat Card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Daily Usage Section
class _DailyUsageSection extends StatelessWidget {
  final List<DailyUsage> dailyUsage;

  const _DailyUsageSection({required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    final maxMessages =
        dailyUsage.map((d) => d.messages).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('每日使用'),
        const SizedBox(height: 12),
        const Text(
          '近 31 天的消息活跃度走势',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 220,
            child: CustomPaint(
              painter: _UsageChartPainter(
                data: dailyUsage,
                maxValue: maxMessages.toDouble(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppTheme.brandColor, label: '消息数'),
          ],
        ),
      ],
    );
  }
}

/// Usage Chart Painter
class _UsageChartPainter extends CustomPainter {
  final List<DailyUsage> data;
  final double maxValue;

  _UsageChartPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.brandColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.brandColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const horizontalPadding = 18.0;
    const topPadding = 16.0;
    const bottomPadding = 34.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - topPadding - bottomPadding;

    final path = Path();
    final fillPath = Path();

    final barWidth = chartWidth / (data.length <= 1 ? 1 : data.length - 1);
    final stepX = barWidth;

    for (int i = 0; i < data.length; i++) {
      final x = horizontalPadding + i * stepX;
      final normalizedValue = data[i].messages / maxValue;
      final y = size.height - bottomPadding - (normalizedValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - bottomPadding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    final lastX = horizontalPadding + (data.length - 1) * stepX;
    fillPath.lineTo(lastX, size.height - bottomPadding);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw dots
    for (int i = 0; i < data.length; i++) {
      final x = horizontalPadding + i * stepX;
      final normalizedValue = data[i].messages / maxValue;
      final y = size.height - bottomPadding - (normalizedValue * chartHeight);

      final dotPaint = Paint()
        ..color = AppTheme.surface
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(x, y), 4, linePaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    // Draw X-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final interval = data.length > 18 ? 6 : 4;
    for (int i = 0; i < data.length; i += interval) {
      final x = horizontalPadding + i * stepX;
      final date = data[i].date;
      final label = '${date.month}/${date.day}';

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: AppTheme.neutral500,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }
  }

  @override
  bool shouldRepaint(_UsageChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

/// Legend Item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }
}

/// Tools Usage Section
class _ToolsUsageSection extends StatelessWidget {
  final Map<String, int> toolsUsage;

  const _ToolsUsageSection({required this.toolsUsage});

  @override
  Widget build(BuildContext context) {
    final sortedTools = toolsUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('工具使用'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: sortedTools.map((entry) {
              return _UsageBarItem(
                label: entry.key,
                value: entry.value,
                total: toolsUsage.values.reduce((a, b) => a + b),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Model Usage Section
class _ModelUsageSection extends StatelessWidget {
  final Map<String, int> modelUsage;

  const _ModelUsageSection({required this.modelUsage});

  @override
  Widget build(BuildContext context) {
    final sortedModels = modelUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('模型使用'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: sortedModels
                .map((entry) => _UsageBarItem(
                      label: entry.key,
                      value: entry.value,
                      total: modelUsage.values.reduce((a, b) => a + b),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Usage Bar Item
class _UsageBarItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;

  const _UsageBarItem({
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$value 次',
                style: TextStyle(
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
              value: percentage,
              minHeight: 6,
              backgroundColor: AppTheme.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity Info Section
class _ActivityInfoSection extends StatelessWidget {
  final UsageStatistics statistics;

  const _ActivityInfoSection({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('活跃度'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: [
              _InfoRow('首次使用', _formatDate(statistics.firstSessionDate)),
              const Divider(),
              _InfoRow('最近使用', _formatDate(statistics.lastSessionDate)),
              const Divider(),
              _InfoRow('总会话数', '${statistics.totalSessions} 次'),
              const Divider(),
              _InfoRow('活跃天数', '${statistics.daysActive} 天'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

/// Info Row
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Title
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
