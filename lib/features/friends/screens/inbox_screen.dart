import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/auth_models.dart'
    show InboxItem, InboxItemType, UserSearchResult, FriendStatus;
import '../data/friends_repository.dart';
import '../data/inbox_repository.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  List<InboxItem> _feedItems = [];
  List<UserSearchResult> _incomingRequests = [];
  List<UserSearchResult> _requestedFriends = [];
  List<UserSearchResult> _acceptedFriends = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = ref.read(authStateProvider).credentials?.token;
    Object? feedError;
    Object? relationshipError;
    List<InboxItem> feedItems = const [];
    List<UserSearchResult> relationships = const [];

    try {
      feedItems = await InboxRepository.instance.getFeedItems(token: token);
    } catch (error) {
      feedError = error;
    }

    try {
      relationships =
          await FriendsRepository.instance.getRelationshipUsers(token: token);
    } catch (error) {
      relationshipError = error;
    }

    try {
      final incoming = <UserSearchResult>[];
      final requested = <UserSearchResult>[];
      final accepted = <UserSearchResult>[];
      for (final user in relationships) {
        switch (user.status) {
          case FriendStatus.pending:
            incoming.add(user);
            break;
          case FriendStatus.requested:
            requested.add(user);
            break;
          case FriendStatus.friend:
            accepted.add(user);
            break;
          case FriendStatus.none:
          case FriendStatus.rejected:
            break;
        }
      }

      if (!mounted) {
        return;
      }

      final message = _mergeLoadErrors(feedError, relationshipError);
      setState(() {
        _feedItems = feedItems;
        _incomingRequests = incoming;
        _requestedFriends = requested;
        _acceptedFriends = accepted;
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyErrorMessage(error);
      });
    }
  }

  String? _mergeLoadErrors(Object? feedError, Object? relationshipError) {
    if (feedError == null && relationshipError == null) {
      return null;
    }
    if (feedError == null && relationshipError != null) {
      return _friendlyErrorMessage(relationshipError);
    }
    if (feedError != null && relationshipError == null) {
      return null;
    }
    return _friendlyErrorMessage(feedError!);
  }

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
          content: Text('处理失败：${_friendlyErrorMessage(error)}'),
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
          content: Text('处理失败：${_friendlyErrorMessage(error)}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 404) {
        return '当前账号的收件箱数据尚未准备好，请稍后下拉重试。';
      }
      if (statusCode == 401 || statusCode == 403) {
        return '登录状态已失效，请重新登录后再查看收件箱。';
      }
      if (statusCode != null && statusCode >= 500) {
        return '服务端暂时不可用，请稍后重试。';
      }
      return '网络请求失败，请检查网络或服务器地址。';
    }
    return '收件箱加载失败，请稍后重试。';
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: false,
      child: _buildBody(),
    );

    if (!widget.showAppBar) {
      return ColoredBox(
        color: AppTheme.neutral50,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('收件箱'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.friendsSearch),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: '添加好友',
          ),
        ],
      ),
      body: body,
    );
  }

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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          if (_feedItems.isNotEmpty)
            _SectionCard(
              title: '动态更新',
              children: _feedItems
                  .map(
                    (item) => _InboxFeedTile(
                      item: item,
                      onTap: item.userId != null
                          ? () => context.push(
                                AppRoutes.userProfileDetail(item.userId!),
                              )
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

class _InboxFeedbackView extends StatelessWidget {
  const _InboxFeedbackView({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
                height: 1.6,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _InboxFeedTile extends StatelessWidget {
  const _InboxFeedTile({
    required this.item,
    this.onTap,
  });

  final InboxItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(item).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(item), color: _iconColor(item)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  if ((item.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatRelative(item.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(InboxItem item) {
    switch (item.type) {
      case InboxItemType.friendRequest:
        return Icons.person_add_alt_1_rounded;
      case InboxItemType.message:
        return Icons.mail_outline_rounded;
      case InboxItemType.notification:
        return Icons.notifications_none_rounded;
    }
  }

  Color _iconColor(InboxItem item) {
    switch (item.type) {
      case InboxItemType.friendRequest:
        return AppTheme.brandColor;
      case InboxItemType.message:
        return AppTheme.infoColor;
      case InboxItemType.notification:
        return AppTheme.warningColor;
    }
  }

  String _formatRelative(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    }
    return '${time.month}/${time.day}';
  }
}

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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
        TextButton(
          onPressed: onReject,
          child: Text(rejectLabel),
        ),
        FilledButton(
          onPressed: onAccept,
          child: Text(acceptLabel),
        ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
