import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';
import '../../session/domain/session_stats.dart';

part 'session_list_item_body.dart';
part 'session_list_item_helpers.dart';
part 'session_list_item_menu.dart';
part 'sessions_list_content.dart';
part 'sessions_list_feedback.dart';

/// 会话列表项
class SessionListItem extends ConsumerWidget {
  const SessionListItem({
    super.key,
    required this.session,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  final Session session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionMessages = ref.watch(
      sessionStateProvider.select(
        (state) => state.whenOrNull(
          ready: (_, sessionMessages, __) =>
              sessionMessages[session.id]?.messages,
        ),
      ),
    );
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: sessionMessages,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _SessionItemIcon(session: session),
            const SizedBox(width: 12),
            Expanded(
                child: _SessionListItemBody(session: session, stats: stats)),
            _SessionListMenuButton(session: session),
          ],
        ),
      ),
    );
  }
}

/// 会话列表组件
class SessionsList extends ConsumerWidget {
  const SessionsList({
    super.key,
    this.showActiveOnly = false,
    this.onSessionTap,
    this.onNewSessionTap,
  });

  final bool showActiveOnly;
  final void Function(String sessionId)? onSessionTap;
  final VoidCallback? onNewSessionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);
    return sessionState.when(
      initial: () => const _SessionsListLoadingView(),
      loading: () => const _SessionsListLoadingView(),
      ready: (sessions, sessionMessages, machines) {
        final sessionList = showActiveOnly
            ? sessions.values.where((s) => s.active).toList()
            : sessions.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (sessionList.isEmpty) {
          return _SessionsListEmptyView(
            showActiveOnly: showActiveOnly,
            onNewSessionTap: onNewSessionTap,
          );
        }

        return _SessionsListContent(
          sessions: sessionList,
          onSessionTap: onSessionTap,
          onNewSessionTap: onNewSessionTap,
        );
      },
      error: (message) => _SessionsListErrorView(message: message),
    );
  }
}
