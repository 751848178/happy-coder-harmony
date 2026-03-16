part of 'avatar_styles.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.style = AvatarStyle.gradient,
    this.size = 48,
    this.imageUrl,
    this.onTap,
    this.color,
    this.badge,
    this.isOnline = false,
  });

  final String name;
  final AvatarStyle style;
  final double size;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? badge;
  final bool isOnline;

  String get initials => _getInitials(name);
  Color get _color => color ?? AvatarColors.random(name.hashCode);

  @override
  Widget build(BuildContext context) {
    final avatarWidget =
        imageUrl != null ? _buildImageAvatar() : _buildStyledAvatar();
    final wrapped = (badge != null || isOnline)
        ? _buildWithBadge(avatarWidget)
        : avatarWidget;
    return InkWell(onTap: onTap, child: wrapped);
  }

  Widget _buildStyledAvatar() {
    return switch (style) {
      AvatarStyle.gradient => const GradientAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        ),
      AvatarStyle.pixelated => const PixelatedAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        ),
      AvatarStyle.brutalist => const BrutalistAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
      AvatarStyle.minimalist => const MinimalistAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        ),
      AvatarStyle.glass => const GlassAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        ),
      AvatarStyle.outline => const OutlineAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        ),
    };
  }

  Widget _buildImageAvatar() {
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildStyledAvatar(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWithBadge(Widget avatar) {
    final badgeSize = size * 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              right: -badgeSize / 4,
              top: -badgeSize / 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                constraints: BoxConstraints(minWidth: badgeSize),
                child: badge!,
              ),
            ),
        ],
      ),
    );
  }
}

String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}
