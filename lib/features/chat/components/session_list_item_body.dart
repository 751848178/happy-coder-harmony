part of 'session_list.dart';

class _SessionItemIcon extends StatelessWidget {
  const _SessionItemIcon({
    required this.session,
    required this.isThinking,
  });

  final Session session;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    return SessionAgentAvatar(
      session: session,
      isActive: session.active,
      isThinking: isThinking,
    );
  }
}

class _SessionListItemBody extends StatelessWidget {
  const _SessionListItemBody({
    required this.session,
    this.messages,
    required this.hasLoadedMessages,
    required this.isThinking,
  });

  final Session session;
  final List<ReducerMessage>? messages;
  final bool hasLoadedMessages;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final titleText = resolveSessionListTitle(session);
    final activitySnapshot = resolveSessionListActivitySnapshot(
      session: session,
      messages: messages,
      hasLoadedMessages: hasLoadedMessages,
    );
    final statusSnapshot = resolveSessionListStatusSnapshot(
      messages: messages,
      isThinking: isThinking,
      isActive: session.active,
    );
    final lastActivityAt = activitySnapshot.lastMessageAt;
    final timeText = lastActivityAt == null
        ? null
        : formatSessionListUpdatedAt(lastActivityAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titleText,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: activitySnapshot.isSyncing
                  ? Container(
                      key: const ValueKey<String>('syncing'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '待同步',
                        style: TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : timeText == null
                      ? const SizedBox.shrink(
                          key: ValueKey<String>('empty'),
                        )
                      : Text(
                          key: ValueKey<String>(timeText),
                          timeText,
                          style: const TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 12,
                          ),
                        ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _SessionListPreviewLine(
            key: ValueKey<String>(
              '${statusSnapshot?.kind.name ?? "none"}:'
              '${activitySnapshot.phase.name}:${activitySnapshot.previewText}',
            ),
            activitySnapshot: activitySnapshot,
            statusSnapshot: statusSnapshot,
          ),
        ),
      ],
    );
  }
}

class _SessionListPreviewLine extends StatelessWidget {
  const _SessionListPreviewLine({
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
        color: activitySnapshot.isSyncing
            ? AppTheme.neutral500
            : AppTheme.neutral600,
        fontSize: 12,
        height: 1.35,
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
