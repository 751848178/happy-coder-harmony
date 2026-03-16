part of 'user_profile_screen.dart';

Future<void> _loadFriendProfile(_UserProfileScreenState state) async {
  final routerState = GoRouterState.of(state.context);
  final userId = state.widget.userId ??
      routerState.pathParameters['id'] ??
      routerState.uri.queryParameters['id'];
  if (userId == null || userId.isEmpty) {
    state._updateView(() {
      state._errorMessage = '用户 ID 未提供';
    });
    return;
  }
  state._updateView(() {
    state._isLoading = true;
    state._errorMessage = null;
  });
  try {
    final token = state.ref.read(authStateProvider).credentials?.token;
    final user = await FriendsRepository.instance.getUserProfile(
      userId,
      token: token,
    );
    state._updateView(() {
      state._user = user;
      state._isLoading = false;
    });
  } catch (error) {
    state._updateView(() {
      state._isLoading = false;
      state._errorMessage = '加载用户资料失败: $error';
    });
  }
}

Future<void> _addFriendFromProfile(_UserProfileScreenState state) async {
  final user = state._user;
  if (user == null || state._isAddingFriend) {
    return;
  }
  state._updateView(() {
    state._isAddingFriend = true;
    state._errorMessage = null;
  });
  try {
    final token = state.ref.read(authStateProvider).credentials?.token;
    await FriendsRepository.instance.addFriend(user.id, token: token);
    final nextStatus = user.status == FriendStatus.friend
        ? FriendStatus.pending
        : FriendStatus.friend;
    state._updateView(() {
      state._user = UserSearchResult(
        id: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        githubUsername: user.githubUsername,
        status: nextStatus,
      );
      state._isAddingFriend = false;
    });
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text(
          switch (nextStatus) {
            FriendStatus.pending => '已发送好友请求',
            FriendStatus.friend => '已接受好友请求',
            _ => '操作成功',
          },
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  } catch (error) {
    state._updateView(() {
      state._isAddingFriend = false;
      state._errorMessage = '操作失败: $error';
    });
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text('操作失败: $error'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

String _profileInitials(String name) {
  if (name.isEmpty) {
    return '?';
  }
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name.substring(0, 1).toUpperCase();
}

bool _canAddFriend(UserSearchResult? user) {
  if (user == null) {
    return false;
  }
  return user.status == FriendStatus.none ||
      user.status == FriendStatus.rejected;
}

IconData _profileActionIcon(FriendStatus status) {
  switch (status) {
    case FriendStatus.none:
      return Icons.person_add;
    case FriendStatus.requested:
      return Icons.timer;
    case FriendStatus.pending:
      return Icons.check;
    case FriendStatus.friend:
      return Icons.check_circle;
    case FriendStatus.rejected:
      return Icons.refresh;
  }
}

String _profileActionText(FriendStatus status) {
  switch (status) {
    case FriendStatus.none:
      return '添加好友';
    case FriendStatus.requested:
      return '请求已发送';
    case FriendStatus.pending:
      return '接受请求';
    case FriendStatus.friend:
      return '已是好友';
    case FriendStatus.rejected:
      return '重新请求';
  }
}
