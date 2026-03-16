part of 'app_router.dart';

List<RouteBase> _buildProfileAndFriendRoutes() {
  return [
    GoRoute(
      path: AppRoutes.profiles,
      name: AppRoutes.profilesName,
      builder: (context, state) => const ProfileListScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileDetail,
      name: AppRoutes.profileDetailName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.uri.queryParameters['id'],
        (id) => ProfileDetailScreen(profileId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.friends,
      name: AppRoutes.friendsName,
      builder: (context, state) => const FriendsListScreen(),
    ),
    GoRoute(
      path: '/friends/index',
      builder: (context, state) => const FriendsListScreen(),
    ),
    GoRoute(
      path: AppRoutes.friendsSearch,
      name: AppRoutes.friendsSearchName,
      builder: (context, state) => const FriendsSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.userProfile,
      name: AppRoutes.userProfileName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.uri.queryParameters['id'],
        (id) => UserProfileScreen(userId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.userProfileById,
      name: AppRoutes.userProfileByIdName,
      builder: (context, state) => _buildRequiredPathWidget(
        state.pathParameters['id'],
        (id) => UserProfileScreen(userId: id),
      ),
    ),
    GoRoute(
      path: AppRoutes.inbox,
      name: AppRoutes.inboxName,
      builder: (context, state) => const InboxScreen(),
    ),
    GoRoute(
      path: '/inbox/index',
      builder: (context, state) => const InboxScreen(),
    ),
  ];
}
