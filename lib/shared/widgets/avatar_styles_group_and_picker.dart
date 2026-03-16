part of 'avatar_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final visibleCount = math.min(avatars.length, maxVisible);
    final hasMore = avatars.length > maxVisible;
    final remainingCount = avatars.length - maxVisible;
    final groupWidth = size + (size * overlap * (visibleCount - 1));
    return SizedBox(
      width: groupWidth + (hasMore ? size * 0.6 : 0),
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
              child: _buildMoreBadge(size, remainingCount),
            ),
        ],
      ),
    );
  }
}

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
                Avatar(name: name, style: style, size: 40),
                const SizedBox(height: 8),
                Text(
                  _avatarStyleName(style),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? AppTheme.brandColor : AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

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
        border: OutlineInputBorder(),
      ),
      items: AvatarStyle.values.map((style) {
        return DropdownMenuItem<AvatarStyle>(
          value: style,
          child: Row(
            children: [
              Avatar(name: name, style: style, size: 24),
              const SizedBox(width: 12),
              Text(_avatarStyleName(style)),
            ],
          ),
        );
      }).toList(),
      onChanged: (style) {
        if (style != null) onStyleChanged(style);
      },
    );
  }
}

Widget _buildMoreBadge(double size, int remainingCount) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppTheme.neutral200,
      shape: BoxShape.circle,
      border: Border.all(color: AppTheme.surface, width: 2),
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
  );
}

String _avatarStyleName(AvatarStyle style) {
  return switch (style) {
    AvatarStyle.gradient => '渐变',
    AvatarStyle.pixelated => '像素',
    AvatarStyle.brutalist => '粗野',
    AvatarStyle.minimalist => '极简',
    AvatarStyle.glass => '毛玻璃',
    AvatarStyle.outline => '轮廓',
  };
}
