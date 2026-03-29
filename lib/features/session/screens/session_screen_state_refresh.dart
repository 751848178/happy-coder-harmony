part of 'session_screen.dart';

extension _SessionScreenStateRefresh on _SessionScreenState {
  Future<void> _refreshSessionState() async {
    if (_isRefreshingSessionState) {
      return;
    }

    final authState = ref.read(authStateProvider);
    final credentials = authState.credentials;
    if (credentials == null) {
      return;
    }

    _setSessionRefreshing(true);

    try {
      await Future.wait([
        ref.read(sessionStateProvider.notifier).loadSessions(force: true),
        ref.read(socketStateProvider.notifier).initialize(
              machineId: credentials.machineId,
              token: credentials.token,
            ),
      ]);
      await ref.read(sessionStateProvider.notifier).loadSessionMessages(
            widget.sessionId,
            force: true,
            throwOnError: true,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新连接状态失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setSessionRefreshing(false);
    }
  }

  Future<void> _syncSessionMessagesFromRemote() async {
    if (_isRefreshingSessionState) {
      return;
    }

    _setSessionRefreshing(true);
    try {
      await ref
          .read(sessionStateProvider.notifier)
          .syncFullSessionMessagesFromRemote(
            widget.sessionId,
            throwOnError: true,
          );
      await _maybeAutoApprovePendingTools();
      _scheduleScrollToLatest(force: true);
      _scheduleViewportStateRefresh();
      if (!mounted) {
        return;
      }
      final syncedCount = ref
              .read(sessionStateProvider.notifier)
              .getSessionMessages(widget.sessionId)
              ?.messages
              .length ??
          0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已从 PC 全量同步消息，共 $syncedCount 条'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步全部消息失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setSessionRefreshing(false);
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
