part of 'friends_list_screen.dart';

extension _FriendsListScreenContent on _FriendsListScreenState {
  Widget _buildCurrentContent() {
    if (_isLoading) return _buildLoadingView();
    if (_errorMessage != null) return _buildErrorView();
    if (_isSearching) return _buildSearchingView();
    if (_searchController.text.isNotEmpty) return _buildSearchResultsView();
    return _buildFriendsListView();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.neutral400),
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
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsListView() {
    if (_friends.isEmpty) return _buildEmptyView();
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

  Widget _buildSearchResultsView() {
    if (_searchResults.isEmpty) return _buildNoResultsView();
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

  Widget _buildLoadingView() => _buildFeedbackView(
        icon: const CircularProgressIndicator(color: AppTheme.brandColor),
        title: '加载中...',
      );

  Widget _buildSearchingView() => _buildFeedbackView(
        icon: const CircularProgressIndicator(color: AppTheme.brandColor),
        title: '搜索中...',
      );

  Widget _buildErrorView() => _buildFeedbackView(
        icon: Icon(
          Icons.error_outline,
          size: 64,
          color: AppTheme.neutral400,
        ),
        title: _errorMessage ?? '加载失败',
        action: ElevatedButton(
          onPressed: _loadFriends,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('重试'),
        ),
      );

  Widget _buildEmptyView() => _buildFeedbackView(
        icon: Icon(
          Icons.people_outline,
          size: 64,
          color: AppTheme.neutral400,
        ),
        title: '暂无好友',
        subtitle: '通过用户搜索添加好友',
      );

  Widget _buildNoResultsView() => _buildFeedbackView(
        icon: Icon(
          Icons.search_off,
          size: 64,
          color: AppTheme.neutral400,
        ),
        title: '未找到匹配的用户',
        subtitle: '尝试使用其他关键词搜索',
      );

  Widget _buildFeedbackView({
    required Widget icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: AppTheme.neutral900),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}
