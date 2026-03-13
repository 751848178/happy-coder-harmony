import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/auth_models.dart' show Friend, FriendStatus, UserSearchResult;
import '../data/friends_repository.dart';

/// Friends List Screen
///
/// Shows all friends and provides options to add new friends
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Friend> _friends = [];
  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Load friends list
  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;

      final friends = await FriendsRepository.instance.getFriends(token: token);
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载好友列表失败: $e';
        _isLoading = false;
      });
    }
  }

  /// Search users
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;

      final results = await FriendsRepository.instance.searchUsers(query, token: token);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      // Error is shown inline
    }
  }

  /// Add friend
  Future<void> _addFriend(String uid, String name) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;

      await FriendsRepository.instance.addFriend(uid, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已向 $name 发送好友请求'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      // Reload friends list
      _loadFriends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加好友失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Remove friend
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
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已移除好友'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload friends list
        _loadFriends();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除好友失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('好友'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _isSearching
                          ? _buildSearchingView()
                          : _searchController.text.isNotEmpty
                              ? _buildSearchResultsView()
                              : _buildFriendsListView(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.neutral200),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppTheme.neutral400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '搜索用户...',
                hintStyle: TextStyle(color: AppTheme.neutral400),
                border: InputBorder.none,
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() {
                  _isSearching = false;
                  _searchResults = [];
                });
              },
            ),
        ],
      ),
    );
  }

  /// Build friends list view
  Widget _buildFriendsListView() {
    if (_friends.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.separated(
      itemCount: _friends.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _FriendListItem(
        friend: _friends[index],
        onRemove: () => _removeFriend(
          _friends[index].userId,
          _friends[index].name,
        ),
      ),
    );
  }

  /// Build search results view
  Widget _buildSearchResultsView() {
    if (_searchResults.isEmpty) {
      return _buildNoResultsView();
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _UserSearchResultItem(
        user: _searchResults[index],
        onAdd: () => _addFriend(
          _searchResults[index].id,
          _searchResults[index].name,
        ),
      ),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }

  /// Build searching view
  Widget _buildSearchingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text(
            '搜索中...',
            style: TextStyle(color: AppTheme.neutral600),
          ),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '加载失败',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.neutral900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFriends,
            child: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty view
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无好友',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '通过用户搜索添加好友',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build no results view
  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          const Text(
            '未找到匹配的用户',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用其他关键词搜索',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friend list item widget
class _FriendListItem extends StatelessWidget {
  const _FriendListItem({
    required this.friend,
    required this.onRemove,
  });

  final Friend friend;
  final VoidCallback onRemove;

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.userProfileDetail(friend.userId)),
      leading: _buildAvatar(),
      title: Text(
        friend.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: Text(
        _formatDate(friend.createdAt),
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.neutral600,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showOptionsDialog(context),
        tooltip: '更多',
      ),
    );
  }

  Widget _buildAvatar() {
    if (friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(friend.avatarUrl!),
        radius: 24,
      );
    }
    return CircleAvatar(
      backgroundColor: AppTheme.brandColor,
      radius: 24,
      child: Text(
        _getInitials(friend.name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '刚刚添加';
      }
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
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

/// User search result item widget
class _UserSearchResultItem extends StatelessWidget {
  const _UserSearchResultItem({
    required this.user,
    required this.onAdd,
  });

  final UserSearchResult user;
  final VoidCallback onAdd;

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go(AppRoutes.userProfileDetail(user.id)),
      leading: _buildAvatar(),
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
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          _buildStatusBadge(user.status),
        ],
      ),
      trailing: _buildActionButton(context),
    );
  }

  Widget _buildAvatar() {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.avatarUrl!),
        radius: 24,
      );
    }
    return CircleAvatar(
      backgroundColor: AppTheme.brandColor,
      radius: 24,
      child: Text(
        _getInitials(user.name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FriendStatus status) {
    String label;
    Color color;

    switch (status) {
      case FriendStatus.none:
        label = '添加好友';
        color = AppTheme.brandColor;
        break;
      case FriendStatus.pending:
        label = '待接受请求';
        color = Colors.orange;
        break;
      case FriendStatus.friend:
        label = '已是好友';
        color = Colors.green;
        break;
      case FriendStatus.rejected:
        label = '已拒绝';
        color = AppTheme.errorColor;
        break;
      case FriendStatus.requested:
        label = '已发送请求';
        color = Colors.blue;
        break;
    }

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
    switch (user.status) {
      case FriendStatus.none:
        return ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('添加'),
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      case FriendStatus.pending:
        return ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('接受'),
          onPressed: () async {
            // Accept friend request
            onAdd();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      default:
        // Already friends or rejected - show profile
        return IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            context.go(AppRoutes.userProfileDetail(user.id));
          },
        );
    }
  }
}
