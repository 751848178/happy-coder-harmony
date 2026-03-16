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

    _updateState(() {
      _isRefreshingSessionState = true;
    });

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
      if (mounted) {
        _updateState(() {
          _isRefreshingSessionState = false;
        });
      }
    }
  }

  String _createLocalMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }
}
