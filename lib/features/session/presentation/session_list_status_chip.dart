import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/session_list_preview.dart';

class SessionListStatusChip extends StatelessWidget {
  const SessionListStatusChip({
    super.key,
    required this.status,
  });

  final SessionListStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    final spec = _statusSpecFor(status.kind);
    final icon = status.isThinking
        ? SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: spec.color,
            ),
          )
        : Icon(
            spec.icon,
            size: 12,
            color: spec.color,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: spec.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionListStatusChipSpec {
  const _SessionListStatusChipSpec({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

_SessionListStatusChipSpec _statusSpecFor(SessionListStatusKind kind) {
  switch (kind) {
    case SessionListStatusKind.waitingPermission:
      return const _SessionListStatusChipSpec(
        icon: Icons.lock_clock_outlined,
        color: AppTheme.warningColor,
      );
    case SessionListStatusKind.running:
      return const _SessionListStatusChipSpec(
        icon: Icons.play_circle_outline_rounded,
        color: AppTheme.infoColor,
      );
    case SessionListStatusKind.thinking:
      return const _SessionListStatusChipSpec(
        icon: Icons.sync_rounded,
        color: AppTheme.brandColor,
      );
    case SessionListStatusKind.failed:
      return const _SessionListStatusChipSpec(
        icon: Icons.error_outline_rounded,
        color: AppTheme.errorColor,
      );
    case SessionListStatusKind.interrupted:
      return const _SessionListStatusChipSpec(
        icon: Icons.cancel_outlined,
        color: AppTheme.warningColor,
      );
    case SessionListStatusKind.completed:
      return const _SessionListStatusChipSpec(
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.successColor,
      );
    case SessionListStatusKind.inactive:
      return const _SessionListStatusChipSpec(
        icon: Icons.pause_circle_outline_rounded,
        color: AppTheme.neutral500,
      );
  }
}
