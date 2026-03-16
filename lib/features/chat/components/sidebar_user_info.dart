part of 'sidebar.dart';

class UserInfo extends ConsumerWidget {
  const UserInfo({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user =
        authState.isAuthenticated ? ref.watch(currentUserProvider) : null;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.brandColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: AppTheme.neutral500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              iconSize: 18,
              color: AppTheme.neutral600,
              onPressed: () => _showSidebarUserMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSidebarUserMenu(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSidebarMenuItem(icon: Icons.person_outline, label: '个人资料'),
            _buildSidebarMenuItem(icon: Icons.settings_outlined, label: '设置'),
            _buildSidebarMenuItem(
              icon: Icons.logout,
              label: '退出登录',
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.push(AppRoutes.auth);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildSidebarMenuItem({
  required IconData icon,
  required String label,
  VoidCallback? onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: AppTheme.neutral600),
    title: Text(label,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
    onTap: onTap ?? () {},
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}
