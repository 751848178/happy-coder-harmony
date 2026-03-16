part of 'sessions_screen.dart';

class _SessionListItemContent extends StatelessWidget {
  const _SessionListItemContent({
    required this.dragExtent,
    required this.session,
    required this.stats,
    required this.groupName,
    required this.onTap,
    required this.onLongPress,
    required this.onCloseActions,
  });

  final double dragExtent;
  final Session session;
  final SessionStats stats;
  final String? groupName;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onCloseActions;

  @override
  Widget build(BuildContext context) {
    final directoryLabel = _directoryBadgeLabel(session);
    final statusBadge = session.thinking == true
        ? _SessionThinkingBadge(since: session.thinkingAt)
        : session.active
            ? const _SessionStatusBadge(
                label: '活跃',
                color: AppTheme.successColor,
              )
            : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (dragExtent != 0) {
            onCloseActions();
            return;
          }
          onTap();
        },
        onLongPress: dragExtent == 0 ? onLongPress : onCloseActions,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: statusBadge == null
                          ? 0
                          : session.thinking == true
                              ? 112
                              : 72,
                    ),
                    child: Row(
                      children: [
                        _SessionLeadingIcon(
                          isActive: session.active,
                          isThinking: session.thinking == true,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title.isNotEmpty
                                    ? session.title
                                    : '未命名会话',
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
                              if ((groupName != null &&
                                      groupName!.isNotEmpty) ||
                                  directoryLabel != null) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (groupName != null &&
                                        groupName!.isNotEmpty)
                                      _SessionBadge(
                                        icon: Icons.folder_open_outlined,
                                        label: groupName!,
                                        color: AppTheme.brandColor,
                                      ),
                                    if (directoryLabel != null)
                                      _SessionBadge(
                                        icon: Icons.folder_open_outlined,
                                        label: directoryLabel,
                                        color: AppTheme.brandColor,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Padding(
                    padding: const EdgeInsets.only(right: 26),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: AppTheme.neutral500),
                        const SizedBox(width: 4),
                        Text(
                          _formatSessionUpdatedAt(session.updatedAt),
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.neutral600),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Icon(
                          Icons.message_outlined,
                          size: 13,
                          color: AppTheme.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.messageCount} 条消息',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.neutral600),
                        ),
                        if (stats.hasChanges) ...[
                          const SizedBox(width: AppTheme.spacingMd),
                          Icon(
                            Icons.edit_note_rounded,
                            size: 13,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${stats.changedLineCount} 行改动',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (statusBadge != null)
                Positioned(top: 0, right: 0, child: statusBadge),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.neutral400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
