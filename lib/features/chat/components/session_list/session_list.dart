import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/session/domain/session_list_preview.dart';
import '../../../../features/session/domain/session_recency.dart';
import '../../../../features/session/presentation/session_agent_avatar.dart';
import '../../../../features/session/presentation/session_list_status_chip.dart';
import '../../../../shared/utils/extensions.dart';

part 'item_body.dart';
part 'item_helpers.dart';
part 'item_menu.dart';
part 'sessions_list_content.dart';
part 'sessions_list_feedback.dart';

class _SessionListItemSelection {
  const _SessionListItemSelection({
    required this.session,
  });

  final Session session;

  @override
  bool operator ==(Object other) {
    return other is _SessionListItemSelection &&
        identical(session, other.session);
  }

  @override
  int get hashCode => identityHashCode(session);
}

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
    final selection = ref.watch(
      sessionStateProvider.select(
        (state) => state.when(
          initial: () => _SessionListItemSelection(
            session: session,
          ),
          loading: () => _SessionListItemSelection(
            session: session,
          ),
          ready: (sessions, _, __) {
            final current = sessions[session.id] ?? session;
            return _SessionListItemSelection(
              session: current,
            );
          },
          error: (_) => _SessionListItemSelection(
            session: session,
          ),
        ),
      ),
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
            _SessionItemIcon(
              session: selection.session,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SessionListItemBody(
                session: selection.session,
              ),
            ),
            _SessionListMenuButton(session: selection.session),
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
    final isLoading = ref.watch(
      sessionStateProvider.select(
        (state) => state.when(
          initial: () => true,
          loading: () => true,
          ready: (_, __, ___) => false,
          error: (_) => false,
        ),
      ),
    );
    if (isLoading) {
      return const _SessionsListLoadingView();
    }

    final String? errorMessage = ref.watch(
      sessionStateProvider.select<String?>(
        (state) => state.whenOrNull(error: (message) => message),
      ),
    );
    if (errorMessage != null) {
      return _SessionsListErrorView(message: errorMessage);
    }

    final sessionList = ref.watch(
      sessionStateProvider.select(
        (state) => state.when(
          initial: () => const <Session>[],
          loading: () => const <Session>[],
          ready: (sessions, _, __) {
            final items = (showActiveOnly
                ? sessions.values.where((session) => session.active).toList()
                : sessions.values.toList())
              ..sort(compareSessionsByStableListOrder);
            return items;
          },
          error: (_) => const <Session>[],
        ),
      ),
    );

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
  }
}
