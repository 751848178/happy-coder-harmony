import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/auth_models.dart'
    show FriendStatus, InboxItem, InboxItemType, UserSearchResult;
import '../../data/friends_repository.dart';
import '../../data/inbox_repository.dart';

part 'actions.dart';
part 'body.dart';
part 'feedback.dart';
part 'feed_tile.dart';
part 'helpers.dart';
part 'user_tiles.dart';

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

  void _startInboxLoading() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  void _applyInboxData({
    required List<InboxItem> feedItems,
    required List<UserSearchResult> incoming,
    required List<UserSearchResult> requested,
    required List<UserSearchResult> accepted,
    required String? message,
  }) {
    setState(() {
      _feedItems = feedItems;
      _incomingRequests = incoming;
      _requestedFriends = requested;
      _acceptedFriends = accepted;
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _applyInboxFailure(Object error) {
    setState(() {
      _isLoading = false;
      _errorMessage = friendlyInboxErrorMessage(error);
    });
  }

  Future<void> _loadInbox() async {
    _startInboxLoading();

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

      _applyInboxData(
        feedItems: feedItems,
        incoming: incoming,
        requested: requested,
        accepted: accepted,
        message: mergeInboxLoadErrors(feedError, relationshipError),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _applyInboxFailure(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(top: false, child: _buildBody());
    if (!widget.showAppBar) {
      return ColoredBox(color: AppTheme.neutral50, child: body);
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
}
