part of 'machine_path_selector.dart';

class _MachineChip extends StatelessWidget {
  const _MachineChip({
    required this.machine,
    required this.isSelected,
    required this.onTap,
  });

  final MachineInfo machine;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              machine.isLocal ? Icons.computer : Icons.cloud,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              machine.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathChip extends StatelessWidget {
  const _PathChip({
    required this.path,
    required this.isSelected,
    required this.onTap,
  });

  final PathInfo path;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.15)
              : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.brandColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              path.icon,
              size: 14,
              color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              path.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
