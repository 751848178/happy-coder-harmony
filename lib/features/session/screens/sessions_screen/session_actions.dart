part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  void _openSession(Session session) {
    unawaited(
      openSessionDetail(
        context: context,
        ref: ref,
        sessionId: session.id,
      ),
    );
  }

  Future<void> _refreshSessionList() async {
    if (_isRefreshingSessions) {
      return;
    }

    _setRefreshingSessions(true);

    try {
      await Future.wait([
        _runSessionListAutoSync(forceSessions: true),
        ref
            .read(sessionStateProvider.notifier)
            .loadMachines(force: true, allowFailure: true),
      ]);
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
