import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../../core/theme/app_theme.dart';

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

  double get _avatarSize {
    switch (size) {
      case UserCardSize.small:
        return 32;
      case UserCardSize.medium:
        return 48;
      case UserCardSize.large:
        return 64;
      case UserCardSize.extraLarge:
        return 96;
    }
  }

  double get _fontSize {
    switch (size) {
      case UserCardSize.small:
        return 12;
      case UserCardSize.medium:
        return 14;
      case UserCardSize.large:
        return 16;
      case UserCardSize.extraLarge:
        return 18;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case UserCardSize.small:
        return const EdgeInsets.all(8);
      case UserCardSize.medium:
        return const EdgeInsets.all(12);
      case UserCardSize.large:
        return const EdgeInsets.all(16);
      case UserCardSize.extraLarge:
        return const EdgeInsets.all(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case UserCardStyle.minimal:
        return _buildMinimalCard();
      case UserCardStyle.detailed:
        return _buildDetailedCard();
      case UserCardStyle.profile:
        return _buildProfileCard();
      case UserCardStyle.compact:
        return _buildCompactCard();
    }
  }

  /// Minimal style card - avatar + name only
  Widget _buildMinimalCard() {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            if (size != UserCardSize.small) ...[
              const SizedBox(width: 12),
              _buildName(),
            ],
          ],
        ),
      ),
    );

    if (trailing != null) {
      return Row(
        children: [
          Expanded(child: card),
          trailing!,
        ],
      );
    }
    return card;
  }

  /// Detailed style card - full information
  Widget _buildDetailedCard() {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildName(),
                  if (showBio && user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildBio(),
                  ],
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildEmail(),
                  ],
                  _buildActions(),
                ],
              ),
            ),
            if (trailing != null) const SizedBox(width: 12),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: content,
    );
  }

  /// Profile style card - large profile display
  Widget _buildProfileCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neutral200),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                AppTheme.brandColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 16),
              _buildName(center: true),
              if (showBio && user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildBio(center: true),
              ],
              const SizedBox(height: 16),
              _buildEmail(center: true),
              const SizedBox(height: 20),
              _buildActions(center: true),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact style card - horizontal, minimal padding
  Widget _buildCompactCard() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildName(),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  /// Avatar widget
  Widget _buildAvatar() {
    final initials = _getInitials();

    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(),
      ),
      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(initials),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallbackAvatar(initials, isLoading: true);
                },
              ),
            )
          : _buildFallbackAvatar(initials),
    );
  }

  /// Fallback avatar when image fails or no avatar URL
  Widget _buildFallbackAvatar(String initials, {bool isLoading = false}) {
    return Center(
      child: isLoading
          ? SizedBox(
              width: _avatarSize * 0.5,
              height: _avatarSize * 0.5,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _avatarSize * 0.4,
              ),
            ),
    );
  }

  /// Name widget
  Widget _buildName({bool center = false}) {
    return Text(
      user.name,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Bio widget
  Widget _buildBio({bool center = false}) {
    return Text(
      user.bio ?? '',
      style: TextStyle(
        fontSize: _fontSize - 1,
        color: AppTheme.neutral600,
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Email widget
  Widget _buildEmail({bool center = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.email_outlined,
          size: _fontSize + 2,
          color: AppTheme.neutral500,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            user.email,
            style: TextStyle(
              fontSize: _fontSize - 1,
              color: AppTheme.neutral500,
            ),
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Action buttons
  Widget _buildActions({bool center = false}) {
    if (style == UserCardStyle.minimal || style == UserCardStyle.compact) {
      return const SizedBox.shrink();
    }

    final buttons = <Widget>[];

    if (onMessage != null) {
      buttons.add(
        _ActionButton(
          icon: Icons.message_outlined,
          label: '消息',
          onPressed: onMessage!,
          size: size,
        ),
      );
    }

    if (onFollow != null) {
      buttons.add(
        _ActionButton(
          icon: isFollowing ? Icons.person_remove : Icons.person_add,
          label: isFollowing ? '取消关注' : '关注',
          onPressed: onFollow!,
          size: size,
          isSecondary: isFollowing,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: buttons,
      ),
    );
  }

  /// Get initials from name
  String _getInitials() {
    final parts = user.name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Get avatar color based on user id
  Color _getAvatarColor() {
    final colors = [
      AppTheme.brandColor,
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
    ];

    final index = user.id.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.size,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final UserCardSize size;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final buttonSize = size == UserCardSize.small
        ? 32.0
        : size == UserCardSize.extraLarge
            ? 48.0
            : 40.0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? AppTheme.neutral100
              : AppTheme.brandColor,
          foregroundColor: isSecondary
              ? AppTheme.neutral700
              : Colors.white,
          minimumSize: Size(buttonSize, buttonSize),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
