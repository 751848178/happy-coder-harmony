import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../session/domain/session_stats.dart';
import '../domain/usage_models.dart';

part 'usage_statistics_screen_breakdowns.dart';
part 'usage_statistics_screen_chart.dart';
part 'usage_statistics_screen_content.dart';
part 'usage_statistics_screen_data.dart';
part 'usage_statistics_screen_info.dart';
part 'usage_statistics_screen_summary.dart';

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

  Future<void> _loadStatistics({bool force = true}) async {
    setState(() => _isLoading = true);

    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    try {
      await sessionNotifier.loadSessions(force: force);
    } catch (error) {
      Logger.warning(
          'Usage statistics reload failed, using cached sessions: $error');
    }

    final statistics = _buildStatisticsFromSessions(sessionNotifier);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _statistics = statistics;
    });
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
            onPressed: () => _loadStatistics(force: true),
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
              : const Center(child: Text('暂无统计数据')),
    );
  }
}
