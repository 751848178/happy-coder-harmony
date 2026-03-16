part of 'enhanced_new_session_screen.dart';

class _PermissionModeSelector extends StatelessWidget {
  const _PermissionModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  final String selectedMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const modes = [
      _ModeItem('auto', '自动', Icons.auto_mode),
      _ModeItem('read', '只读', Icons.visibility),
      _ModeItem('edit', '编辑', Icons.edit),
      _ModeItem('full', '完全访问', Icons.admin_panel_settings),
    ];
    return _buildModeWrap(modes, selectedMode, onSelected);
  }
}

class _ModelModeSelector extends StatelessWidget {
  const _ModelModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  final String selectedMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const modes = [
      _ModeItem('auto', '自动选择', Icons.auto_awesome),
      _ModeItem('fast', '快速模式', Icons.flash_on),
      _ModeItem('balanced', '平衡模式', Icons.balance),
      _ModeItem('quality', '高质量模式', Icons.high_quality),
    ];
    return _buildModeWrap(modes, selectedMode, onSelected);
  }
}

Widget _buildModeWrap(
  List<_ModeItem> modes,
  String selectedMode,
  ValueChanged<String> onSelected,
) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: modes
        .map(
          (mode) => _ModeCard(
            item: mode,
            isSelected: selectedMode == mode.id,
            onTap: () => onSelected(mode.id),
          ),
        )
        .toList(),
  );
}

class _ModeItem {
  const _ModeItem(this.id, this.name, this.icon);

  final String id;
  final String name;
  final IconData icon;
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _ModeItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              item.icon,
              size: 16,
              color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppTheme.brandColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 40, color: AppTheme.neutral400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
