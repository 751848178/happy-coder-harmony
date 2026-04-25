import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';

part 'actions.dart';
part 'content.dart';
part 'variants.dart';

/// User card size variant
enum UserCardSize {
  small,
  medium,
  large,
  extraLarge,
}

/// User card style variant
enum UserCardStyle {
  minimal,
  detailed,
  profile,
  compact,
}

/// User Card Widget
///
/// Reusable component for displaying user information
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.size = UserCardSize.medium,
    this.style = UserCardStyle.detailed,
    this.onTap,
    this.onMessage,
    this.onFollow,
    this.showBio = true,
    this.isFollowing = false,
    this.trailing,
  });

  final User user;
  final UserCardSize size;
  final UserCardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onFollow;
  final bool showBio;
  final bool isFollowing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      UserCardStyle.minimal => _buildMinimalCard(),
      UserCardStyle.detailed => _buildDetailedCard(),
      UserCardStyle.profile => _buildProfileCard(),
      UserCardStyle.compact => _buildCompactCard(),
    };
  }
}
