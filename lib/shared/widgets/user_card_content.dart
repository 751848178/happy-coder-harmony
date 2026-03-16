part of 'user_card.dart';

extension _UserCardContent on UserCard {
  double get _avatarSize => switch (size) {
        UserCardSize.small => 32,
        UserCardSize.medium => 48,
        UserCardSize.large => 64,
        UserCardSize.extraLarge => 96,
      };

  double get _fontSize => switch (size) {
        UserCardSize.small => 12,
        UserCardSize.medium => 14,
        UserCardSize.large => 16,
        UserCardSize.extraLarge => 18,
      };

  EdgeInsets get _padding => switch (size) {
        UserCardSize.small => const EdgeInsets.all(8),
        UserCardSize.medium => const EdgeInsets.all(12),
        UserCardSize.large => const EdgeInsets.all(16),
        UserCardSize.extraLarge => const EdgeInsets.all(20),
      };

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
                errorBuilder: (_, __, ___) => _buildFallbackAvatar(initials),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildFallbackAvatar(initials, isLoading: true);
                },
              ),
            )
          : _buildFallbackAvatar(initials),
    );
  }

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

  Widget _buildBio({bool center = false}) {
    return Text(
      user.bio ?? '',
      style: TextStyle(fontSize: _fontSize - 1, color: AppTheme.neutral600),
      textAlign: center ? TextAlign.center : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmail({bool center = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.email_outlined,
            size: _fontSize + 2, color: AppTheme.neutral500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            user.email,
            style:
                TextStyle(fontSize: _fontSize - 1, color: AppTheme.neutral500),
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    final parts = user.name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _getAvatarColor() {
    final colors = [
      AppTheme.brandColor,
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];
    return colors[user.id.hashCode.abs() % colors.length];
  }
}
