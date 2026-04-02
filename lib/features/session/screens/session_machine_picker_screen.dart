import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

/// 机器选择页
///
/// 通过 `context.push<String>` 打开，`context.pop(machineId)` 返回选择结果。
class SessionMachinePickerScreen extends ConsumerStatefulWidget {
  const SessionMachinePickerScreen({
    super.key,
    this.selectedMachineId,
  });

  final String? selectedMachineId;

  @override
  ConsumerState<SessionMachinePickerScreen> createState() =>
      _SessionMachinePickerScreenState();
}

class _SessionMachinePickerScreenState
    extends ConsumerState<SessionMachinePickerScreen> {
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
        ready: (sessions, _, machines) => (sessions, machines),
      ),
    ));
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final machines = <_MachineOption>[];
    final seenIds = <String>{};

    for (final machine in sessionNotifier.machines) {
      if (seenIds.add(machine.id)) {
        machines.add(
          _MachineOption(
            id: machine.id,
            name: machine.name,
            subtitle: machine.platform ?? 'Unknown',
          ),
        );
      }
    }

    for (final session in sessionNotifier.sessions) {
      final machineId = session.metadata?['machineId']?.toString();
      if (machineId == null || machineId.isEmpty || !seenIds.add(machineId)) {
        continue;
      }
      machines.add(
        _MachineOption(
          id: machineId,
          name: session.metadata?['host']?.toString() ?? machineId,
          subtitle: session.path ?? '来自最近会话',
        ),
      );
    }

    if (machines.isEmpty) {
      machines.add(const _MachineOption(
        id: 'local',
        name: '本地机器',
        subtitle: 'localhost',
      ));
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('选择机器'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: machines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final machine = machines[index];
          final isSelected = machine.id == widget.selectedMachineId;
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: BorderSide(
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
                child: const Icon(Icons.computer, color: AppTheme.brandColor),
              ),
              title: Text(machine.name),
              subtitle: Text(machine.subtitle),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.brandColor)
                  : null,
              onTap: () => Navigator.of(context).pop(machine.id),
            ),
          );
        },
      ),
    );
  }
}

class _MachineOption {
  const _MachineOption({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String subtitle;
}
