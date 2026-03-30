part of 'session_screen.dart';

extension _SessionScreenMessageForward on _SessionScreenState {
  String _formatForwardSessionUpdatedAt(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7} 周前';
    }
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }

  Future<void> _forwardMessageToOtherSession(String text) async {
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final candidateSessions = sessionNotifier.sessions
        .where((session) => session.id != widget.sessionId)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (candidateSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还没有可转发的其他会话'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final targetSession = await _showForwardSessionPicker(candidateSessions);
    if (targetSession == null || !mounted) {
      return;
    }

    final latestSession =
        sessionNotifier.getSession(targetSession.id) ?? targetSession;
    final nextDraft = mergeForwardedMessageIntoDraft(
      existingDraft: latestSession.draft,
      forwardedText: text,
    );
    sessionNotifier.updateDraft(targetSession.id, nextDraft);

    final targetTitle = resolveSessionListTitle(latestSession);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已转发到「$targetTitle」草稿'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: '打开',
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) {
              return;
            }
            context.push(AppRoutes.sessionDetail(targetSession.id));
          },
        ),
      ),
    );
  }

  Future<Session?> _showForwardSessionPicker(List<Session> sessions) {
    return showModalBottomSheet<Session>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaHeight = MediaQuery.sizeOf(context).height;
        final sheetHeight = (sessions.length * 76.0 + 160.0)
            .clamp(280.0, mediaHeight * 0.76)
            .toDouble();
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择目标会话',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '转发内容会写入目标会话的输入草稿，不会自动发送。',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutral600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppTheme.neutral200,
                        ),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final title = resolveSessionListTitle(session);
                          final subtitle = session.path ??
                              session.metadata?['path']?.toString() ??
                              session.metadata?['description']?.toString() ??
                              '最近更新 ${_formatForwardSessionUpdatedAt(session.updatedAt)}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppTheme.brandColor,
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: session.draft?.trim().isNotEmpty == true
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoColor
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      '有草稿',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.infoColor,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, session),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
