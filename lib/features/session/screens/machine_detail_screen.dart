import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/session_recency.dart';

/// 机器详情页
class MachineDetailScreen extends ConsumerStatefulWidget {
  const MachineDetailScreen({
    super.key,
    required this.machineId,
  });

  final String machineId;

  @override
  ConsumerState<MachineDetailScreen> createState() =>
      _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider.select(
      (s) => s.whenOrNull(
        ready: (sessions, _, machines) => (
          sessions,
          machines,
        ),
      ),
    ));
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final sessions = sessionNotifier.sessions.where((session) {
      final metadataMachineId = session.metadata?['machineId']?.toString();
      return metadataMachineId == widget.machineId;
    }).toList()
      ..sort(compareSessionsByRecency);

    final machine = sessionNotifier.machines
        .where((item) => item.id == widget.machineId)
        .cast<Machine?>()
        .firstOrNull;

    final machineName = machine?.name ?? widget.machineId;
    final machinePlatform = machine?.platform ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('机器详情'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          Uri(
            path: AppRoutes.newFlow,
            queryParameters: {'machineId': widget.machineId},
          ).toString(),
        ),
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('在此机器上新建会话'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              side: BorderSide(color: AppTheme.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '机器信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: '机器 ID', value: widget.machineId),
                  _InfoRow(label: '显示名称', value: machineName),
                  _InfoRow(label: '平台', value: machinePlatform),
                  _InfoRow(label: '关联会话', value: '${sessions.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '最近会话',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('当前机器下还没有会话。'),
              ),
            )
          else
            ...sessions.map(
              (session) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: BorderSide(color: AppTheme.neutral200),
                ),
                child: ListTile(
                  title: Text(session.title.isEmpty ? '未命名会话' : session.title),
                  subtitle: Text(session.path ?? session.tag ?? '无路径信息'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(AppRoutes.sessionDetail(session.id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.neutral600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
