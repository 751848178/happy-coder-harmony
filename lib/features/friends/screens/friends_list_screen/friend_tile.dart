part of 'friends_list_screen.dart';

class _FriendListItem extends StatelessWidget {
  const _FriendListItem({
    required this.friend,
    required this.onRemove,
  });

  final Friend friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.userProfileDetail(friend.userId)),
      leading: _buildFriendAvatar(friend.name, friend.avatarUrl),
      title: Text(
        friend.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: Text(
        _formatFriendAddedAt(friend.createdAt),
        style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showOptionsDialog(context),
        tooltip: '更多',
      ),
    );
  }

  Widget _buildFriendAvatar(String name, String? avatarUrl) {
    return _buildAvatar(name, avatarUrl);
  }

  void _showOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('移除好友'),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('查看资料'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.userProfileDetail(friend.userId));
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAvatar(String name, String? avatarUrl) {
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    return CircleAvatar(
      backgroundImage: NetworkImage(avatarUrl),
      radius: 24,
    );
  }
  return CircleAvatar(
    backgroundColor: AppTheme.brandColor,
    radius: 24,
    child: Text(
      _buildInitials(name),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  );
}

String _buildInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name.substring(0, 1).toUpperCase();
}

String _formatFriendAddedAt(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inDays < 1) {
    if (difference.inHours < 1) return '刚刚添加';
    return '${difference.inHours} 小时前';
  }
  if (difference.inDays < 7) return '${difference.inDays} 天前';
  return '${date.year}/${date.month}/${date.day}';
}
