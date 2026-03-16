part of 'friends_list_screen.dart';

extension _FriendsListScreenActions on _FriendsListScreenState {
  Future<void> _loadFriends() async {
    _updateView(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;
      final friends = await FriendsRepository.instance.getFriends(token: token);
      _updateView(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      _updateView(() {
        _errorMessage = '加载好友列表失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _updateView(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _updateView(() => _isSearching = true);

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;
      final results = await FriendsRepository.instance.searchUsers(
        query,
        token: token,
      );
      _updateView(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      _updateView(() => _isSearching = false);
    }
  }

  Future<void> _addFriend(String uid, String name) async {
    _updateView(() => _errorMessage = null);

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;
      await FriendsRepository.instance.addFriend(uid, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已向 $name 发送好友请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadFriends();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加好友失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _removeFriend(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除好友'),
        content: Text('确定要移除 $name 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;
      await FriendsRepository.instance.removeFriend(uid, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已移除好友'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadFriends();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移除好友失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
