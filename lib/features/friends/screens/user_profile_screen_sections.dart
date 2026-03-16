part of 'user_profile_screen.dart';

Widget _buildUserProfileHeader(UserSearchResult user) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient:
          LinearGradient(colors: [AppTheme.brandColor, AppTheme.brandDark]),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: Text(
            _profileInitials(user.name),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        _buildUserStatusBadge(user.status),
      ],
    ),
  );
}

Widget _buildUserStatusBadge(FriendStatus status) {
  final (label, color) = switch (status) {
    FriendStatus.none => ('非好友', AppTheme.neutral400),
    FriendStatus.requested => ('已发送请求', Colors.orange),
    FriendStatus.pending => ('待接受', Colors.orange),
    FriendStatus.friend => ('好友', Colors.green),
    FriendStatus.rejected => ('已拒绝', AppTheme.errorColor),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

Widget _buildUserBasicInfoCard(UserSearchResult user) {
  return _UserProfileCard(
    title: '基本信息',
    icon: Icons.person,
    child: Column(
      children: [
        _buildUserInfoRow('用户名', user.name),
        const SizedBox(height: 12),
        _buildUserInfoRow('用户 ID', user.id),
      ],
    ),
  );
}

Widget _buildUserBioCard(UserSearchResult user) {
  return _UserProfileCard(
    title: '简介',
    icon: Icons.description,
    child: Text(
      user.bio!,
      style: const TextStyle(fontSize: 14, color: AppTheme.neutral900),
    ),
  );
}

Widget _buildUserActionCard(
  _UserProfileScreenState state,
  UserSearchResult user,
) {
  final canAdd = _canAddFriend(user);
  return _UserProfileCard(
    title: null,
    icon: null,
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: canAdd ? state._addFriend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canAdd ? AppTheme.brandColor : AppTheme.neutral300,
                foregroundColor: canAdd ? Colors.white : AppTheme.neutral600,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state._isAddingFriend)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(_profileActionIcon(user.status), size: 20),
                  const SizedBox(width: 8),
                  Text(_profileActionText(user.status),
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(state.context).showSnackBar(
                const SnackBar(content: Text('消息功能开发中')),
              );
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('消息'),
            style:
                OutlinedButton.styleFrom(foregroundColor: AppTheme.brandColor),
          ),
        ),
      ],
    ),
  );
}

Widget _buildUserInfoRow(String label, String value) {
  return Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutral900),
        ),
      ),
    ],
  );
}
