import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/session_models.dart';

/// Presence Indicator Widget
///
/// 显示会话的在线状态和实时信息
class PresenceIndicator extends StatelessWidget {
  final PresenceStatus? presence;
  final bool? isThinking;
  final DateTime? thinkingSince;
  final bool showLabel;
  final double? size;

  const PresenceIndicator({
    super.key,
    this.presence,
    this.isThinking,
    this.thinkingSince,
    this.showLabel = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorSize = size ?? 12.0;

    if (isThinking == true) {
      return _ThinkingIndicator(size: indicatorSize, since: thinkingSince);
    }

    final presenceStatus = presence;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PresenceDot(
          isOnline: presenceStatus?.isOnline ?? false,
          size: indicatorSize,
        ),
        if (showLabel && presenceStatus != null) ...[
          const SizedBox(width: 6),
          _PresenceLabel(presence: presenceStatus!),
        ],
      ],
    );
  }
}

/// Presence Dot
class _PresenceDot extends StatelessWidget {
  final bool isOnline;
  final double size;

  const _PresenceDot({
    required this.isOnline,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppTheme.successColor : AppTheme.neutral400,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Presence Label
class _PresenceLabel extends StatelessWidget {
  final PresenceStatus presence;

  const _PresenceLabel({required this.presence});

  String _getPresenceText() {
    if (presence.isOnline) {
      return '在线';
    }
    if (presence.isIdle) {
      return '离线';
    }
    return presence.status;
  }

  Color _getTextColor() {
    if (presence.isOnline) {
      return AppTheme.successColor;
    }
    if (presence.isIdle) {
      return AppTheme.neutral500;
    }
    return AppTheme.brandColor;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _getPresenceText(),
      style: TextStyle(
        fontSize: 12,
        color: _getTextColor(),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Thinking Indicator
class _ThinkingIndicator extends StatelessWidget {
  final double size;
  final DateTime? since;

  const _ThinkingIndicator({
    required this.size,
    this.since,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandColor),
          ),
        ),
        if (since != null) ...[
          const SizedBox(width: 6),
          _ThinkingDuration(since: since!),
        ],
      ],
    );
  }
}

/// Thinking Duration
class _ThinkingDuration extends StatefulWidget {
  final DateTime since;

  const _ThinkingDuration({required this.since});

  @override
  State<_ThinkingDuration> createState() => _ThinkingDurationState();
}

class _ThinkingDurationState extends State<_ThinkingDuration> {
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = DateTime.now().difference(widget.since);
  }

  @override
  void didUpdateWidget(_ThinkingDuration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.since != widget.since) {
      _duration = DateTime.now().difference(widget.since);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        return Text(
          _formatDuration(_duration),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.neutral600,
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 1) return '思考中...';
    if (duration.inSeconds < 60) {
      return '思考 ${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return '思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}

/// Online Users List
class OnlineUsersList extends StatelessWidget {
  final List<SessionPresence> users;
  final String? currentUser;
  final int? maxDisplay;

  const OnlineUsersList({
    super.key,
    required this.users,
    this.currentUser,
    this.maxDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final displayUsers = maxDisplay != null
        ? users.take(maxDisplay!).toList()
        : users;

    if (displayUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          '暂无在线用户',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.neutral500,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '在线用户 (${displayUsers.length})',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 8),
        ...displayUsers.map((user) {
          return _UserTile(
            user: user,
            isCurrentUser: user.userId == currentUser,
          );
        }),
      ],
    );
  }
}

/// User Tile
class _UserTile extends StatelessWidget {
  final SessionPresence user;
  final bool isCurrentUser;

  const _UserTile({
    required this.user,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.brandColor.withOpacity(0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.userName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isCurrentUser
                      ? AppTheme.brandColor
                      : AppTheme.textPrimary,
                ),
              ),
              if (isCurrentUser)
                Text(
                  '(你)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// User Avatar
class _UserAvatar extends StatelessWidget {
  final SessionPresence user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.userName.split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join('');

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _getAvatarColor(user.userId),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];
    final index = userId.hashCode.abs() % colors.length;
    return colors[index];
  }
}

/// Session Usage Stats
class SessionUsageStats extends StatelessWidget {
  final LatestUsage? usage;
  final PresenceStatus? presence;

  const SessionUsageStats({
    super.key,
    this.usage,
    this.presence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          if (presence != null) ...[
            _UsageIcon(
              icon: presence!.isOnline ? Icons.wifi : Icons.wifi_off,
              color: presence!.isOnline ? AppTheme.successColor : AppTheme.neutral400,
            ),
            const SizedBox(width: 16),
          ],
          if (usage != null) ...[
            _UsageIcon(
              icon: Icons.message,
              color: AppTheme.brandColor,
              label: '${usage!.messageCount}',
            ),
            const SizedBox(width: 16),
            _UsageIcon(
              icon: Icons.psychology,
              color: Colors.purple,
              label: _formatNumber(usage!.tokenCount),
            ),
            const SizedBox(width: 16),
            if (usage!.filesAccessed != null)
              _UsageIcon(
                icon: Icons.folder_open,
                color: Colors.orange,
                label: '${usage!.filesAccessed}',
              ),
            const SizedBox(width: 16),
            if (usage!.toolsUsed != null)
              _UsageIcon(
                icon: Icons.build,
                color: Colors.teal,
                label: '${usage!.toolsUsed}',
              ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

/// Usage Icon
class _UsageIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;

  const _UsageIcon({
    required this.icon,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
