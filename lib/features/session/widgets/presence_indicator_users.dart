part of 'presence_indicator.dart';

class OnlineUsersList extends StatelessWidget {
  const OnlineUsersList({
    super.key,
    required this.users,
    this.currentUser,
    this.maxDisplay,
  });

  final List<SessionPresence> users;
  final String? currentUser;
  final int? maxDisplay;

  @override
  Widget build(BuildContext context) {
    final displayUsers =
        maxDisplay != null ? users.take(maxDisplay!).toList() : users;
    if (displayUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          '暂无在线用户',
          style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '在线用户 (${displayUsers.length})',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 8),
        ...displayUsers.map((user) {
          return _UserTile(
            user: user,
            isCurrentUser: user.userId == currentUser,
          );
        }),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isCurrentUser,
  });

  final SessionPresence user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.brandColor.withValues(alpha: 0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.userName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isCurrentUser
                      ? AppTheme.brandColor
                      : AppTheme.textPrimary,
                ),
              ),
              if (isCurrentUser)
                const Text(
                  '(你)',
                  style: TextStyle(fontSize: 11, color: AppTheme.neutral500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final SessionPresence user;

  @override
  Widget build(BuildContext context) {
    final initials = user.userName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join('');
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _presenceAvatarColor(user.userId),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

Color _presenceAvatarColor(String userId) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.red,
  ];
  return colors[userId.hashCode.abs() % colors.length];
}
