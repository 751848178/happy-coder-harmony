part of 'profile_list_screen.dart';

void _showProfileOptionsSheet(
    _ProfileListScreenState state, AIProfile profile) {
  showModalBottomSheet<void>(
    context: state.context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildProfileOptionsHeader(profile),
            const Divider(height: 1),
            _buildProfileActionTiles(state, profile),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showProfileEditBottomSheet(
  _ProfileListScreenState state, {
  AIProfile? profile,
}) async {
  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: state.context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProfileEditSheet(profile: profile),
  );

  if (result == null || !state.mounted) {
    return;
  }
  if (profile == null) {
    await state.ref.read(profileStateProvider.notifier).createProfile(
          _createProfileFromEditResult(result),
        );
    return;
  }
  await state.ref.read(profileStateProvider.notifier).updateProfile(
        _updateProfileFromEditResult(profile, result),
      );
}

void _showProfileDeleteConfirmation(
  _ProfileListScreenState state,
  AIProfile profile,
) {
  showDialog<void>(
    context: state.context,
    builder: (context) => AlertDialog(
      title: const Text('删除配置'),
      content: Text('确认要删除 "${profile.name}" 吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            state.ref
                .read(profileStateProvider.notifier)
                .deleteProfile(profile.id);
            if (state.mounted) {
              ScaffoldMessenger.of(state.context).showSnackBar(
                const SnackBar(
                  content: Text('配置已删除'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}

Widget _buildProfileOptionsHeader(AIProfile profile) {
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
      child: Icon(_providerIconForProfile(profile), color: AppTheme.brandColor),
    ),
    title:
        Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: profile.description != null
        ? Text(profile.description!)
        : Text(profile.providerDisplayName ?? '未知'),
  );
}

Widget _buildProfileActionTiles(
    _ProfileListScreenState state, AIProfile profile) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('编辑'),
        onTap: () {
          Navigator.pop(state.context);
          state._showProfileEditDialog(profile: profile);
        },
      ),
      if (!profile.isBuiltIn)
        ListTile(
          leading: const Icon(Icons.copy),
          title: const Text('克隆'),
          onTap: () async {
            Navigator.pop(state.context);
            await state.ref
                .read(profileStateProvider.notifier)
                .cloneProfile(profile);
            if (state.mounted) {
              ScaffoldMessenger.of(state.context).showSnackBar(
                const SnackBar(
                  content: Text('配置已克隆'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          },
        ),
      ListTile(
        leading: const Icon(Icons.delete_outline),
        title: const Text('删除'),
        textColor: AppTheme.errorColor,
        onTap: () {
          Navigator.pop(state.context);
          state._showDeleteConfirmation(profile);
        },
      ),
    ],
  );
}
