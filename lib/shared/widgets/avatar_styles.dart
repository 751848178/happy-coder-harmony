import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Avatar style type
enum AvatarStyle {
  gradient,
  pixelated,
  brutalist,
  minimalist,
  glass,
  outline,
}

/// Avatar colors
class AvatarColors {
  static const primary = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];

  static const secondary = [
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  static const warm = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFDC2626),
  ];

  static const cool = [
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
  ];

  static Color random(int seed) {
    return primary[seed % primary.length];
  }
}

/// Gradient Avatar Style
class GradientAvatarStyle {
  const GradientAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          color.withValues(alpha: 0.7),
        ],
      ),
      shape: BoxShape.circle,
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}

/// Pixelated Avatar Style
class PixelatedAvatarStyle {
  const PixelatedAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.black,
        width: 2,
      ),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                letterSpacing: size * 0.02,
              ),
            ),
      ),
    );
  }
}

/// Brutalist Avatar Style
class BrutalistAvatarStyle {
  const BrutalistAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: Colors.black,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
      ),
    );
  }
}

/// Minimalist Avatar Style
class MinimalistAvatarStyle {
  const MinimalistAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: TextStyle(
                color: color,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w500,
              ),
            ),
      ),
    );
  }
}

/// Glass Avatar Style
class GlassAvatarStyle {
  const GlassAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.4),
        ],
      ),
      shape: BoxShape.circle,
      border: Border.all(
        color: color.withValues(alpha: 0.5),
        width: 1,
      ),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
}

/// Outline Avatar Style
class OutlineAvatarStyle {
  const OutlineAvatarStyle();

  BoxDecoration getDecoration(Color color, double size) {
    return BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: color,
        width: 2,
      ),
    );
  }

  Widget build({
    required String initials,
    required double size,
    required Color color,
    Widget? child,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: getDecoration(color, size),
      child: Center(
        child: child ??
            Text(
              initials,
              style: TextStyle(
                color: color,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}

/// Universal Avatar Widget
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
    final avatarWidget = imageUrl != null
        ? _buildImageAvatar()
        : _buildStyledAvatar();

    if (badge != null || isOnline) {
      return _buildWithBadge(avatarWidget);
    }

    return InkWell(
      onTap: onTap,
      child: avatarWidget,
    );
  }

  Widget _buildStyledAvatar() {
    switch (style) {
      case AvatarStyle.gradient:
        return const GradientAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
      case AvatarStyle.pixelated:
        return const PixelatedAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
      case AvatarStyle.brutalist:
        return const BrutalistAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
      case AvatarStyle.minimalist:
        return const MinimalistAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
      case AvatarStyle.glass:
        return const GlassAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
      case AvatarStyle.outline:
        return const OutlineAvatarStyle().build(
          initials: initials,
          size: size,
          color: _color,
        );
    }
  }

  Widget _buildImageAvatar() {
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildStyledAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
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
    final badgePosition = Offset(size * 0.7, -badgeSize / 2);

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
                  border: Border.all(
                    color: AppTheme.surface,
                    width: 2,
                  ),
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
                  border: Border.all(
                    color: AppTheme.surface,
                    width: 2,
                  ),
                ),
                constraints: BoxConstraints(minWidth: badgeSize),
                child: badge!,
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// Avatar Group Widget
///
/// Displays multiple avatars in a group
class AvatarGroup extends StatelessWidget {
  const AvatarGroup({
    super.key,
    required this.avatars,
    this.maxVisible = 3,
    this.size = 32,
    this.overlap = 0.5,
  });

  final List<Avatar> avatars;
  final int maxVisible;
  final double size;
  final double overlap;

  int get visibleCount => math.min(avatars.length, maxVisible);
  int get remainingCount => avatars.length - maxVisible;
  bool get hasMore => avatars.length > maxVisible;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();

    final groupWidth = size + (size * overlap * (visibleCount - 1));
    final moreIndicatorSize = size * 0.6;

    return SizedBox(
      width: groupWidth + (hasMore ? moreIndicatorSize : 0),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * size * overlap,
              top: 0,
              child: SizedBox(
                width: size,
                height: size,
                child: Avatar(
                  name: avatars[i].name,
                  style: avatars[i].style,
                  size: size,
                  imageUrl: avatars[i].imageUrl,
                  color: avatars[i].color,
                ),
              ),
            ),
          if (hasMore)
            Positioned(
              left: visibleCount * size * overlap,
              top: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar Style Selector
///
/// Allows users to select an avatar style
class AvatarStyleSelector extends StatelessWidget {
  const AvatarStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
    this.name = '用户名',
  });

  final AvatarStyle selectedStyle;
  final ValueChanged<AvatarStyle> onStyleChanged;
  final String name;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1,
      children: AvatarStyle.values.map((style) {
        final isSelected = style == selectedStyle;
        return InkWell(
          onTap: () => onStyleChanged(style),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.brandColor.withValues(alpha: 0.1)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.brandColor : AppTheme.neutral200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Avatar(
                  name: name,
                  style: style,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  _getStyleName(style),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppTheme.brandColor : AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStyleName(AvatarStyle style) {
    switch (style) {
      case AvatarStyle.gradient:
        return '渐变';
      case AvatarStyle.pixelated:
        return '像素';
      case AvatarStyle.brutalist:
        return '粗野';
      case AvatarStyle.minimalist:
        return '极简';
      case AvatarStyle.glass:
        return '毛玻璃';
      case AvatarStyle.outline:
        return '轮廓';
    }
  }
}

/// Avatar Quick Picker
class AvatarQuickPicker extends StatelessWidget {
  const AvatarQuickPicker({
    super.key,
    required this.name,
    required this.style,
    required this.onStyleChanged,
  });

  final String name;
  final AvatarStyle style;
  final ValueChanged<AvatarStyle> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AvatarStyle>(
      initialValue: style,
      decoration: const InputDecoration(
        labelText: '头像样式',
        border: const OutlineInputBorder(),
      ),
      items: AvatarStyle.values.map((style) {
        return DropdownMenuItem<AvatarStyle>(
          value: style,
          child: Row(
            children: [
              Avatar(name: name, style: style, size: 24),
              const SizedBox(width: 12),
              Text(_getStyleName(style)),
            ],
          ),
        );
      }).toList(),
      onChanged: (style) {
        if (style != null) {
          onStyleChanged(style);
        }
      },
    );
  }

  static String _getStyleName(AvatarStyle style) {
    switch (style) {
      case AvatarStyle.gradient:
        return '渐变';
      case AvatarStyle.pixelated:
        return '像素';
      case AvatarStyle.brutalist:
        return '粗野';
      case AvatarStyle.minimalist:
        return '极简';
      case AvatarStyle.glass:
        return '毛玻璃';
      case AvatarStyle.outline:
        return '轮廓';
    }
  }
}
