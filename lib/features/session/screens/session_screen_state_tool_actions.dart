part of 'session_screen.dart';

extension _SessionScreenStateToolActions on _SessionScreenState {
  Future<void> _approveToolCall(String toolId, {bool showError = true}) async {
    if (_toolActionsInFlight.contains(toolId)) {
      return;
    }

    _updateState(() => _toolActionsInFlight.add(toolId));

    try {
      await ref.read(sessionStateProvider.notifier).submitToolApproval(
            sessionId: widget.sessionId,
            toolId: toolId,
          );
    } catch (e) {
      _autoApprovedToolIds.remove(toolId);
      await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
      if (mounted && showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批准失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        _updateState(() => _toolActionsInFlight.remove(toolId));
      }
    }
  }

  Future<void> _rejectToolCall(String toolId, String? reason) async {
    if (_toolActionsInFlight.contains(toolId)) {
      return;
    }

    _updateState(() => _toolActionsInFlight.add(toolId));

    try {
      await ref.read(sessionStateProvider.notifier).submitToolRejection(
            sessionId: widget.sessionId,
            toolId: toolId,
            reason: reason,
          );
    } catch (e) {
      await ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒绝失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        _updateState(() => _toolActionsInFlight.remove(toolId));
      }
    }
  }

  /// 显示清空消息对话框
  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空消息'),
        content: const Text('确认要清空此会话的所有消息吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearMessages();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 清空消息
  void _clearMessages() {
    try {
      ref
          .read(sessionStateProvider.notifier)
          .clearSessionMessages(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息已清空'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清空失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// 显示权限设置对话框
  void _showPermissionDialog() {
    final session =
        ref.read(sessionStateProvider.notifier).getSession(widget.sessionId);
    if (session == null) {
      return;
    }

    final options = _permissionOptionsFor(session);
    final current = _resolveCurrentPermissionOption(session);
    _showModeSheet(
      title: '权限设置',
      options: options,
      current: current,
      onSelected: (option) {
        ref.read(sessionStateProvider.notifier).updatePermissionMode(
              widget.sessionId,
              option.key,
            );
        Navigator.pop(context);
        unawaited(_maybeAutoApprovePendingTools());
      },
    );
  }
}
