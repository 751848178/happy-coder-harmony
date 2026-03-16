import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/auth_models.dart'
    show Friend, FriendStatus, UserSearchResult;
import '../data/friends_repository.dart';

part 'friends_list_screen_actions.dart';
part 'friends_list_screen_content.dart';
part 'friends_list_screen_friend_tile.dart';
part 'friends_list_screen_search_result_tile.dart';

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

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _updateView(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _updateView(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
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
            _buildSearchBar(),
            const Divider(height: 1),
            Expanded(child: _buildCurrentContent()),
          ],
        ),
      ),
    );
  }
}
