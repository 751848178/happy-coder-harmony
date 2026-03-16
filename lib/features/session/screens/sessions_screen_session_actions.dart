part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  void _openSession(Session session) {
    context.push(AppRoutes.sessionDetail(session.id));
  }

  Future<void> _refreshSessionList() async {
    if (_isRefreshingSessions) {
      return;
    }

    _setRefreshingSessions(true);

    try {
      final notifier = ref.read(sessionStateProvider.notifier);
      await Future.wait([
        notifier.loadSessions(force: true),
        notifier.loadMachines(force: true, allowFailure: true),
      ]);
      final settings = ref.read(settingsStateProvider);
      final hideInactiveByDefault =
          widget.showAppBar && settings.hideInactiveSessions;
      final visibleSessionIds = notifier.sessions
          .where(
            (session) => _matchesSessionFilters(
              session,
              selectedMachineId: widget.selectedMachineId,
              hideInactiveByDefault: hideInactiveByDefault,
            ),
          )
          .map((session) => session.id)
          .toList(growable: false);
      Logger.info(
        'Sessions list refresh will reload message snapshots for ${visibleSessionIds.length} sessions',
      );
      await notifier.refreshSessionMessageSnapshots(visibleSessionIds);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新会话列表失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        _setRefreshingSessions(false);
      }
    }
  }

  Future<void> _deleteSession(Session session) async {
    try {
      await ref.read(sessionStateProvider.notifier).deleteSession(session.id);
      await _updateGroupingState(
        () => _groupingService.assignSession(sessionId: session.id),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除会话「${session.title}」'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
