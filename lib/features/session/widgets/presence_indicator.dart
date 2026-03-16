import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/session_models.dart';

part 'presence_indicator_presence.dart';
part 'presence_indicator_thinking.dart';
part 'presence_indicator_usage.dart';
part 'presence_indicator_users.dart';

/// Presence Indicator Widget
///
/// 显示会话的在线状态和实时信息
class PresenceIndicator extends StatelessWidget {
  const PresenceIndicator({
    super.key,
    this.presence,
    this.isThinking,
    this.thinkingSince,
    this.showLabel = false,
    this.size,
  });

  final PresenceStatus? presence;
  final bool? isThinking;
  final DateTime? thinkingSince;
  final bool showLabel;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = size ?? 12.0;
    if (isThinking == true) {
      return _ThinkingIndicator(size: indicatorSize, since: thinkingSince);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PresenceDot(
          isOnline: presence?.isOnline ?? false,
          size: indicatorSize,
        ),
        if (showLabel && presence != null) ...[
          const SizedBox(width: 6),
          _PresenceLabel(presence: presence!),
        ],
      ],
    );
  }
}
