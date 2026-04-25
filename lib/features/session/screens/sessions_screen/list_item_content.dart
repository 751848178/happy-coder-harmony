part of 'sessions_screen.dart';

const Duration _sessionListImmediateLongPressDelay = Duration(
  milliseconds: 480,
);
const double _sessionListLongPressMoveSlop = 36.0;

class _SessionListItemContent extends StatelessWidget {
  const _SessionListItemContent({
    required this.dragExtent,
    required this.session,
    required this.titleText,
    required this.activitySnapshot,
    required this.statusSnapshot,
    required this.onTap,
    required this.onLongPress,
    required this.onCloseActions,
  });

  final double dragExtent;
  final Session session;
  final String titleText;
  final SessionListActivitySnapshot activitySnapshot;
  final SessionListStatusSnapshot? statusSnapshot;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onCloseActions;

  @override
  Widget build(BuildContext context) {
    return ImmediateLongPressRegion(
      longPressDelay: _sessionListImmediateLongPressDelay,
      moveSlop: _sessionListLongPressMoveSlop,
      onLongPress: () {
        if (dragExtent != 0) {
          onCloseActions();
          return;
        }
        onLongPress?.call();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (dragExtent != 0) {
            onCloseActions();
            return;
          }
          onTap();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SessionLeadingIcon(
                        session: session,
                        isActive: session.active,
                        isThinking: statusSnapshot?.isThinking == true,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    titleText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: session.active
                                          ? AppTheme.neutral900
                                          : AppTheme.neutral600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _SessionListTimeView(
                                    key: ValueKey<String>(
                                      activitySnapshot.isSyncing
                                          ? 'syncing'
                                          : activitySnapshot.lastMessageAt
                                                  ?.millisecondsSinceEpoch
                                                  .toString() ??
                                              'empty',
                                    ),
                                    activitySnapshot: activitySnapshot,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _SessionListPreviewView(
                                key: ValueKey<String>(
                                  '${statusSnapshot?.kind.name ?? "none"}:'
                                  '${activitySnapshot.phase.name}:'
                                  '${activitySnapshot.previewText}',
                                ),
                                activitySnapshot: activitySnapshot,
                                statusSnapshot: statusSnapshot,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.neutral400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionListTimeView extends StatelessWidget {
  const _SessionListTimeView({
    super.key,
    required this.activitySnapshot,
  });

  final SessionListActivitySnapshot activitySnapshot;

  @override
  Widget build(BuildContext context) {
    if (activitySnapshot.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          '待同步',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.infoColor,
          ),
        ),
      );
    }

    final lastActivityAt = activitySnapshot.lastMessageAt;
    if (lastActivityAt == null) {
      return const SizedBox.shrink();
    }

    return Text(
      _formatSessionUpdatedAt(lastActivityAt),
      style: const TextStyle(
        fontSize: 12,
        color: AppTheme.neutral500,
      ),
    );
  }
}

class _SessionListPreviewView extends StatelessWidget {
  const _SessionListPreviewView({
    super.key,
    required this.activitySnapshot,
    required this.statusSnapshot,
  });

  final SessionListActivitySnapshot activitySnapshot;
  final SessionListStatusSnapshot? statusSnapshot;

  @override
  Widget build(BuildContext context) {
    final previewText = Text(
      activitySnapshot.previewText,
      style: TextStyle(
        fontSize: 12,
        color: activitySnapshot.isSyncing
            ? AppTheme.neutral500
            : AppTheme.neutral600,
        height: 1.4,
      ),
      maxLines: activitySnapshot.isSyncing ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );

    if (statusSnapshot == null) {
      return previewText;
    }

    return Row(
      children: [
        SessionListStatusChip(status: statusSnapshot!),
        const SizedBox(width: 8),
        Expanded(child: previewText),
      ],
    );
  }
}
