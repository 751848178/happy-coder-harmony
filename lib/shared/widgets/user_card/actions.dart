part of 'user_card.dart';

extension _UserCardActions on UserCard {
  Widget _buildActions({bool center = false}) {
    if (style == UserCardStyle.minimal || style == UserCardStyle.compact) {
      return const SizedBox.shrink();
    }
    final buttons = <Widget>[
      if (onMessage != null)
        _ActionButton(
          icon: Icons.message_outlined,
          label: '消息',
          onPressed: onMessage!,
          size: size,
        ),
      if (onFollow != null)
        _ActionButton(
          icon: isFollowing ? Icons.person_remove : Icons.person_add,
          label: isFollowing ? '取消关注' : '关注',
          onPressed: onFollow!,
          size: size,
          isSecondary: isFollowing,
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment:
            center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: buttons,
      ),
    );
  }
}

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
    final buttonSize = switch (size) {
      UserCardSize.small => 32.0,
      UserCardSize.extraLarge => 48.0,
      _ => 40.0,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSecondary ? AppTheme.neutral100 : AppTheme.brandColor,
          foregroundColor: isSecondary ? AppTheme.neutral700 : Colors.white,
          minimumSize: Size(buttonSize, buttonSize),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
