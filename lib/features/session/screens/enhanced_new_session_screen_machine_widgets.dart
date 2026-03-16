part of 'enhanced_new_session_screen.dart';

class _MachineSelector extends StatelessWidget {
  const _MachineSelector({
    required this.machines,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Machine> machines;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (machines.isEmpty) {
      return const _EmptyState(message: '暂无可用机器');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: machines
          .map(
            (machine) => _MachineCard(
              machine: machine,
              isSelected: selectedId == machine.id,
              onTap: () => onSelected(machine.id),
            ),
          )
          .toList(),
    );
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({
    required this.machine,
    required this.isSelected,
    required this.onTap,
  });

  final Machine machine;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              machine.status == MachineStatus.online
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              color: machine.status == MachineStatus.online
                  ? AppTheme.successColor
                  : AppTheme.neutral500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              machine.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neutral200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                machine.platform,
                style: TextStyle(fontSize: 11, color: AppTheme.neutral600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
