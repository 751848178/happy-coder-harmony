part of 'inbox_screen.dart';

extension on _InboxScreenState {
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_errorMessage != null &&
        _feedItems.isEmpty &&
        _incomingRequests.isEmpty &&
        _requestedFriends.isEmpty &&
        _acceptedFriends.isEmpty) {
      return _InboxFeedbackView(
        icon: Icons.mark_email_read_outlined,
        title: '暂时无法加载收件箱',
        description: _errorMessage!,
        actionLabel: '重试',
        onAction: _loadInbox,
      );
    }

    if (_feedItems.isEmpty &&
        _incomingRequests.isEmpty &&
        _requestedFriends.isEmpty &&
        _acceptedFriends.isEmpty) {
      return const _InboxFeedbackView(
        icon: Icons.inbox_outlined,
        title: '收件箱是空的',
        description: '目前没有新的动态、好友请求或待处理通知。',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      color: AppTheme.brandColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (_errorMessage != null)
            _InboxInlineWarning(message: _errorMessage!),
          if (_feedItems.isNotEmpty)
            _SectionCard(
              title: '动态更新',
              children: _feedItems
                  .map(
                    (item) => _InboxFeedTile(
                      item: item,
                      onTap: item.userId != null
                          ? () => context
                              .push(AppRoutes.userProfileDetail(item.userId!))
                          : null,
                    ),
                  )
                  .toList(),
            ),
          if (_incomingRequests.isNotEmpty)
            _SectionCard(
              title: '好友请求',
              children: _incomingRequests
                  .map(
                    (user) => _RequestTile(
                      user: user,
                      acceptLabel: '接受',
                      rejectLabel: '忽略',
                      onAccept: () => _acceptFriendRequest(user),
                      onReject: () => _rejectFriendRequest(user),
                      onViewProfile: () =>
                          context.push(AppRoutes.userProfileDetail(user.id)),
                    ),
                  )
                  .toList(),
            ),
          if (_requestedFriends.isNotEmpty)
            _SectionCard(
              title: '我发出的请求',
              children: _requestedFriends
                  .map(
                    (user) => _CompactUserTile(
                      user: user,
                      trailing: const Text(
                        '等待对方确认',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral600,
                        ),
                      ),
                      onTap: () =>
                          context.push(AppRoutes.userProfileDetail(user.id)),
                    ),
                  )
                  .toList(),
            ),
          if (_acceptedFriends.isNotEmpty)
            _SectionCard(
              title: '我的好友',
              children: _acceptedFriends
                  .map(
                    (user) => _CompactUserTile(
                      user: user,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.neutral400,
                      ),
                      onTap: () =>
                          context.push(AppRoutes.userProfileDetail(user.id)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
