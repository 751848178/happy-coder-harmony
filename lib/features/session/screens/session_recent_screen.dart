import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/session_recency.dart';
import '../domain/session_stats.dart';
import '../../../shared/widgets/session_history_list.dart';

/// Upstream-aligned recent sessions: grouped history only.
class SessionRecentScreen extends ConsumerStatefulWidget {
  const SessionRecentScreen({super.key});

  @override
  ConsumerState<SessionRecentScreen> createState() =>
      _SessionRecentScreenState();
}

class _SessionRecentScreenState extends ConsumerState<SessionRecentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionStateProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch sessions so rebuild triggers when sessions change
    ref.watch(sessionStateProvider.select(
      (s) => s.whenOrNull(
        ready: (sessions, _, __) => sessions,
      ),
    ));
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final sessions = [...sessionNotifier.sessions]
      ..sort(compareSessionsByRecency);
    final items = sessions.map(
      (session) {
        final stats = SessionStatsCalculator.fromSession(
          session: session,
          messages: sessionNotifier.getSessionMessages(session.id)?.messages,
        );
        final summary = session.metadata?['summary'];
        final summaryText = summary is Map ? summary['text']?.toString() : null;
        return SessionHistoryItem(
          id: session.id,
          title: session.title.isEmpty ? '未命名会话' : session.title,
          subtitle: summaryText ??
              session.path ??
              session.metadata?['description']?.toString(),
          createdAt: session.activeAt ?? session.updatedAt,
          lastModified: session.updatedAt,
          type: session.tag,
          machine: session.metadata?['host']?.toString(),
          messageCount: stats.messageCount,
          changedLineCount: stats.hasChanges ? stats.changedLineCount : null,
        );
      },
    ).toList();

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('最近会话'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SessionHistoryList(
          items: items,
          onItemTap: (item) => context.push(AppRoutes.sessionDetail(item.id)),
        ),
      ),
    );
  }
}
