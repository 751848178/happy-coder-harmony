part of 'friends_list_screen.dart';

class _UserSearchResultItem extends StatelessWidget {
  const _UserSearchResultItem({
    required this.user,
    required this.onAdd,
  });

  final UserSearchResult user;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.userProfileDetail(user.id)),
      leading: _buildAvatar(user.name, user.avatarUrl),
      title: Text(
        user.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.bio != null) ...[
            const SizedBox(height: 4),
            Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
          ],
          const SizedBox(height: 4),
          _buildStatusBadge(user.status),
        ],
      ),
      trailing: _buildActionButton(context),
    );
  }

  Widget _buildStatusBadge(FriendStatus status) {
    final (label, color) = switch (status) {
      FriendStatus.none => ('添加好友', AppTheme.brandColor),
      FriendStatus.pending => ('待接受请求', Colors.orange),
      FriendStatus.friend => ('已是好友', Colors.green),
      FriendStatus.rejected => ('已拒绝', AppTheme.errorColor),
      FriendStatus.requested => ('已发送请求', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return switch (user.status) {
      FriendStatus.none => ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('添加'),
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      FriendStatus.pending => ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('接受'),
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      _ => IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.go(AppRoutes.userProfileDetail(user.id)),
        ),
    };
  }
}
