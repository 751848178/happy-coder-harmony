part of 'inbox_screen.dart';

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.user,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  final UserSearchResult user;
  final String acceptLabel;
  final String rejectLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(user: user),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onViewProfile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if ((user.bio ?? '').isNotEmpty)
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onReject, child: Text(rejectLabel)),
        FilledButton(onPressed: onAccept, child: Text(acceptLabel)),
      ],
    );
  }
}

class _CompactUserTile extends StatelessWidget {
  const _CompactUserTile({
    required this.user,
    required this.trailing,
    required this.onTap,
  });

  final UserSearchResult user;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _UserAvatar(user: user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if ((user.githubUsername ?? '').isNotEmpty)
                    Text(
                      '@${user.githubUsername}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
  });

  final UserSearchResult user;

  @override
  Widget build(BuildContext context) {
    if ((user.avatarUrl ?? '').isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    }

    final label =
        user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.brandColor.withValues(alpha: 0.14),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.brandColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
