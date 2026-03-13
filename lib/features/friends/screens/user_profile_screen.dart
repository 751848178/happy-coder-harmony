import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/auth_models.dart' show UserSearchResult, FriendStatus;
import '../data/friends_repository.dart';

/// User Profile Screen
///
/// Displays user profile with their information and relationship status
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserSearchResult? _user;
  bool _isLoading = false;
  bool _isAddingFriend = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    final routerState = GoRouterState.of(context);
    final userId = widget.userId ??
        routerState.pathParameters['id'] ??
        routerState.uri.queryParameters['id'];
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = '用户 ID 未提供';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;

      final user = await FriendsRepository.instance.getUserProfile(userId, token: token);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载用户资料失败: $e';
      });
    }
  }

  /// Add friend
  Future<void> _addFriend() async {
    if (_user == null || _isAddingFriend) return;

    setState(() {
      _isAddingFriend = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final token = authState.credentials?.token;

      await FriendsRepository.instance.addFriend(_user!.id, token: token);

      // Update user status to pending or friend
      final updatedUser = UserSearchResult(
        id: _user!.id,
        name: _user!.name,
        avatarUrl: _user!.avatarUrl,
        bio: _user!.bio,
        githubUsername: _user!.githubUsername,
        status: _user!.status == FriendStatus.friend
            ? FriendStatus.pending
            : FriendStatus.friend,
      );

      setState(() {
        _user = updatedUser;
        _isAddingFriend = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_user!.status == FriendStatus.none
                ? '已发送好友请求'
                : _user!.status == FriendStatus.pending
                    ? '已接受好友请求'
                    : '操作成功'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAddingFriend = false;
        _errorMessage = '操作失败: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

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
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('用户资料'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_user == null) {
      return _buildErrorView(errorMessage: '无法加载用户资料');
    }

    return Column(
      children: [
        // Profile header
        _buildProfileHeader(),

        // Profile content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Basic info
              _buildBasicInfoCard(),

              // Bio
              if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildBioCard(),
              ],

              // Action buttons
              const SizedBox(height: 24),
              _buildActionCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandColor,
            AppTheme.brandDark,
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: _user?.avatarUrl != null
                ? NetworkImage(_user!.avatarUrl!)
                : null,
            child: _user != null
                ? Text(
                    _getInitials(_user!.name),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            _user!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Status badge
          _buildStatusBadge(_user!.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FriendStatus status) {
    String label;
    Color color;

    switch (status) {
      case FriendStatus.none:
        label = '非好友';
        color = AppTheme.neutral400;
        break;
      case FriendStatus.requested:
        label = '已发送请求';
        color = Colors.orange;
        break;
      case FriendStatus.pending:
        label = '待接受';
        color = Colors.orange;
        break;
      case FriendStatus.friend:
        label = '好友';
        color = Colors.green;
        break;
      case FriendStatus.rejected:
        label = '已拒绝';
        color = AppTheme.errorColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppTheme.brandColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                '基本信息',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('用户名', _user!.name),
          const SizedBox(height: 12),
          _buildInfoRow('用户 ID', _user!.id),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppTheme.brandColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                '简介',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _user!.bio!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _canAddFriend() ? _addFriend : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canAddFriend()
                      ? AppTheme.brandColor
                      : AppTheme.neutral300,
                  foregroundColor: _canAddFriend()
                      ? Colors.white
                      : AppTheme.neutral600,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isAddingFriend)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        _getActionIcon(),
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _getActionText(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Message button
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement message functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('消息功能开发中')),
                );
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text('消息'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddFriend() {
    if (_user == null) return false;
    return _user!.status == FriendStatus.none || _user!.status == FriendStatus.rejected;
  }

  IconData _getActionIcon() {
    switch (_user!.status) {
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

  String _getActionText() {
    switch (_user!.status) {
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

  Widget _buildErrorView({String? errorMessage}) {
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
            errorMessage ?? '加载失败',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('返回'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
