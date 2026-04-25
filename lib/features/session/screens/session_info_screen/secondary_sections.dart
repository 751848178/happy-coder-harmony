part of 'session_info_screen.dart';

class _SessionPresenceCard extends StatelessWidget {
  const _SessionPresenceCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    final presence = session.presence!;
    return _InfoCard(
      title: '在线状态',
      icon: Icons.people_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('状态', presence.isOnline ? '在线' : '离线'),
          if (presence.lastActiveAt != null) ...[
            const SizedBox(height: 12),
            _InfoRow('最后活跃', formatSessionInfoDateTime(presence.lastActiveAt!)),
          ],
          if (presence.users != null && presence.users!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _InfoSectionHeader('在线用户'),
            const SizedBox(height: 8),
            for (final user in presence.users!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: user.isOnline
                            ? AppTheme.successColor
                            : AppTheme.neutral400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(user.userName),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SessionThinkingCard extends StatelessWidget {
  const _SessionThinkingCard({
    required this.session,
    required this.messages,
  });

  final Session session;
  final List<ReducerMessage> messages;

  @override
  Widget build(BuildContext context) {
    final isThinking = sessionTurnIsThinkingStillBlocking(
      session: session,
      messages: messages,
    );
    final thinkingSince = sessionThinkingStartedAt(
      session: session,
      messages: messages,
    );
    final statusSnapshot = resolveSessionListStatusSnapshot(
      messages: messages,
      isThinking: isThinking,
      isActive: session.active,
    );
    return _InfoCard(
      title: 'AI 状态',
      icon: Icons.psychology,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('思考中', isThinking ? '是' : '否'),
          if (statusSnapshot != null) ...[
            const SizedBox(height: 12),
            _InfoRow('最近状态', statusSnapshot.label),
          ],
          if (thinkingSince != null) ...[
            const SizedBox(height: 12),
            _InfoRow('开始时间', formatSessionInfoDateTime(thinkingSince)),
          ],
        ],
      ),
    );
  }
}

class _SessionUsageCard extends StatelessWidget {
  const _SessionUsageCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    final usage = session.latestUsage!;
    return _InfoCard(
      title: '使用统计',
      icon: Icons.bar_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('消息数', '${usage.messageCount}'),
          const SizedBox(height: 12),
          _InfoRow('Token 数', '${usage.tokenCount}'),
          const SizedBox(height: 12),
          _InfoRow('统计时间', formatSessionInfoDateTime(usage.timestamp)),
          if (usage.filesAccessed != null) ...[
            const SizedBox(height: 12),
            _InfoRow('访问文件数', '${usage.filesAccessed}'),
          ],
          if (usage.toolsUsed != null) ...[
            const SizedBox(height: 12),
            _InfoRow('使用工具数', '${usage.toolsUsed}'),
          ],
        ],
      ),
    );
  }
}

class _SessionDraftCard extends StatelessWidget {
  const _SessionDraftCard({
    required this.session,
  });

  final Session session;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: '未发送草稿',
      icon: Icons.edit_note,
      child: _InfoContent(session.draft!),
    );
  }
}
