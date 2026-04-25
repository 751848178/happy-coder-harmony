part of 'friends_search_screen.dart';

extension _FriendsSearchScreenBody on _FriendsSearchScreenState {
  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _FriendsSearchMessage(
        text: _errorMessage!,
        color: AppTheme.errorColor,
      );
    }
    if (_searchController.text.trim().isEmpty) {
      return const _FriendsSearchMessage(
        text: '输入用户名后即可搜索并发送好友请求。',
        alignCenter: true,
      );
    }
    if (_results.isEmpty) {
      return const _FriendsSearchMessage(text: '没有找到匹配的用户。');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _FriendsSearchResultTile(
        user: _results[index],
        onAdd: _addFriend,
      ),
    );
  }
}

class _FriendsSearchMessage extends StatelessWidget {
  const _FriendsSearchMessage({
    required this.text,
    this.color = AppTheme.neutral600,
    this.alignCenter = false,
  });

  final String text;
  final Color color;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: TextStyle(color: color),
          textAlign: alignCenter ? TextAlign.center : null,
        ),
      ),
    );
  }
}

class _FriendsSearchResultTile extends StatelessWidget {
  const _FriendsSearchResultTile({
    required this.user,
    required this.onAdd,
  });

  final UserSearchResult user;
  final Future<void> Function(UserSearchResult user) onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.neutral200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.brandColor.withValues(alpha: 0.12),
          child: Text(
            user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.brandColor,
            ),
          ),
        ),
        title: Text(user.name),
        subtitle: Text(_buildSubtitle()),
        trailing: FilledButton(
          onPressed: () => onAdd(user),
          child: const Text('添加'),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    return [
      if (user.githubUsername != null && user.githubUsername!.isNotEmpty)
        '@${user.githubUsername}',
      if (user.bio != null && user.bio!.isNotEmpty) user.bio!,
    ].join(' · ');
  }
}
