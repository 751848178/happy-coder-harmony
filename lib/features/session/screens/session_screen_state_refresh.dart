part of 'session_screen.dart';

extension _SessionScreenStateRefresh on _SessionScreenState {
  /// Refresh button: fetch latest messages incrementally + reconnect socket.
  /// Uses force: false so only new messages after lastSeq are fetched,
  /// not a full reload.  The "sync all" menu item does full reload.
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
        ref
            .read(sessionStateProvider.notifier)
            .loadMachines(force: true, allowFailure: true),
        ref.read(socketStateProvider.notifier).initialize(
              machineId: credentials.machineId,
              token: credentials.token,
            ),
      ]);
      // Incremental fetch — only pulls messages after lastSeq.
      await ref.read(sessionStateProvider.notifier).loadSessionMessages(
            widget.sessionId,
            throwOnError: true,
          );
      _scheduleScrollToLatest(force: true);
      _scheduleViewportStateRefresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      _setSessionRefreshing(false);
    }
  }

  /// "Sync all messages" menu item: full reload from server.
  /// Uses force: true (afterSeq = 0) to fetch every message.
  /// Shows independent loading state so it doesn't conflict with refresh button.
  Future<void> _syncSessionMessagesFromRemote() async {
    if (_isSyncingAllMessages) {
      return;
    }

    _isSyncingAllMessages = true;
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
      _isSyncingAllMessages = false;
      _setSessionRefreshing(false);
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
