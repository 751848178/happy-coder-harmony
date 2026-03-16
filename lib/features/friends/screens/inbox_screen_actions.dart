part of 'inbox_screen.dart';

extension on _InboxScreenState {
  Future<void> _acceptFriendRequest(UserSearchResult user) async {
    try {
      final token = ref.read(authStateProvider).credentials?.token;
      await FriendsRepository.instance.addFriend(user.id, token: token);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已接受 ${user.name} 的好友请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadInbox();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('处理失败：${friendlyInboxErrorMessage(error)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(UserSearchResult user) async {
    try {
      final token = ref.read(authStateProvider).credentials?.token;
      await FriendsRepository.instance.removeFriend(user.id, token: token);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已忽略 ${user.name} 的好友请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadInbox();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('处理失败：${friendlyInboxErrorMessage(error)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
