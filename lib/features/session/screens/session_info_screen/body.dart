part of 'session_info_screen.dart';

class _SessionInfoBody extends StatelessWidget {
  const _SessionInfoBody({
    required this.session,
    required this.stats,
    required this.messages,
  });

  final Session session;
  final SessionStats stats;
  final List<ReducerMessage> messages;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SessionStatusCard(session: session, stats: stats),
          const SizedBox(height: AppTheme.spacingMd),
          _SessionTimeCard(session: session),
          const SizedBox(height: AppTheme.spacingMd),
          _SessionPermissionCard(session: session),
          if (session.presence != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SessionPresenceCard(session: session),
          ],
          if (session.thinking != null || messages.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SessionThinkingCard(
              session: session,
              messages: messages,
            ),
          ],
          if (session.latestUsage != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SessionUsageCard(session: session),
          ],
          if (session.path != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SessionPathCard(session: session),
          ],
          if (session.draft != null && session.draft!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SessionDraftCard(session: session),
          ],
        ],
      ),
    );
  }
}
