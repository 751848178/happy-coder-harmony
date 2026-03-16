part of 'enhanced_new_session_screen.dart';

class _PathChip extends StatelessWidget {
  const _PathChip({required this.path, required this.onTap});

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(path, style: const TextStyle(fontSize: 12)),
      avatar: const Icon(Icons.folder, size: 16),
      onPressed: onTap,
      backgroundColor: AppTheme.neutral100,
    );
  }
}

class _ProfileSelector extends StatelessWidget {
  const _ProfileSelector({
    required this.profiles,
    required this.selectedId,
    required this.onSelected,
    required this.onEdit,
  });

  final List<ProfileSummary> profiles;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: profiles
            .map(
              (profile) => _ProfileTile(
                profile: profile,
                isSelected: selectedId == profile.id,
                onSelected: () => onSelected(profile.id),
                onEdit: () => onEdit(profile.id),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  final ProfileSummary profile;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
          color:
              isSelected ? AppTheme.brandColor.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            _buildSelectionIndicator(),
            const SizedBox(width: 12),
            Expanded(child: _buildTitleRow()),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: '编辑',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppTheme.brandColor : AppTheme.neutral400,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandColor,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Text(
          profile.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        if (profile.isDefault) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.brandColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '默认',
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }
}
