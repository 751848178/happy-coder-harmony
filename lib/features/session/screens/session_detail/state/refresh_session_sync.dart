part of '../session_detail.dart';

extension _SessionScreenRefreshSessionSync on _SessionScreenState {
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
      ]).timeout(const Duration(seconds: 15));
      if (!_hasNewerMessages &&
          !_isLoadingOlderMessages &&
          !_isLoadingNewerMessages &&
          _viewportController.programmaticScrollActivity == 0) {
        // Incremental fetch — only pulls messages after lastSeq.
        await ref.read(sessionStateProvider.notifier).loadSessionMessages(
              widget.sessionId,
              throwOnError: true,
              messageWindowSize: SessionServiceNotifier
                  .sessionDetailAutomaticMessageWindowSize,
            );
        _syncMessagesFromRepository();
        _scheduleScrollToLatest(force: true);
      } else {
        Logger.info(
          '[SessionRefresh] skip message window replacement '
          'session=${widget.sessionId} hasNewer=$_hasNewerMessages '
          'loadingOlder=$_isLoadingOlderMessages '
          'loadingNewer=$_isLoadingNewerMessages '
          'prog=${_viewportController.programmaticScrollActivity}',
        );
      }
      await _ensureArchivedMessageHistoryAccessible();
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

    _isSyncingAllMessagesN.value = true;
    _setSessionRefreshing(true);
    try {
      await ref
          .read(sessionStateProvider.notifier)
          .syncFullSessionMessagesFromRemote(
            widget.sessionId,
            throwOnError: true,
          );
      _syncMessagesFromRepository();
      await _refreshArchivedMessageCount();
      _isHydratingArchiveHistoryN.value = false;
      await _maybeAutoApprovePendingTools();
      _scheduleScrollToLatest(force: true);
      _scheduleViewportStateRefresh();
      if (!mounted) {
        return;
      }
      final syncedCount = ref
              .read(sessionStateProvider.notifier)
              .getSessionMessages(widget.sessionId)
              ?.totalMessageCount ??
          0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已归档完整历史，共 $syncedCount 条；内存仅保留当前窗口'),
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
      _isSyncingAllMessagesN.value = false;
      _setSessionRefreshing(false);
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
