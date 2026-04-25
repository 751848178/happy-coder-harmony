import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/auth_models.dart'
    show FriendStatus, UserSearchResult;
import '../../data/friends_repository.dart';

part 'actions.dart';
part 'card.dart';
part 'content.dart';
part 'sections.dart';

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

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  Future<void> _loadUserProfile() => _loadFriendProfile(this);

  Future<void> _addFriend() => _addFriendFromProfile(this);

  @override
  Widget build(BuildContext context) {
    return _buildUserProfileScaffold(this);
  }
}
