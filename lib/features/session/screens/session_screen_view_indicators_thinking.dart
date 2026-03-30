part of 'session_screen.dart';

extension _SessionScreenThinkingIndicators on _SessionScreenState {
  Widget _buildFloatingThinkingBadge(
    Session session,
    List<ReducerMessage> messages,
  ) {
    final thinkingSince = sessionThinkingStartedAt(
      session: session,
      messages: messages,
      manualThinkingOverride: _manualThinkingOverride,
    );
    final label =
        thinkingSince == null ? 'AI 思考中' : _formatThinkingLabel(thinkingSince);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.16)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.brandColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatThinkingLabel(DateTime since) {
    final duration = DateTime.now().difference(since);
    if (duration.inSeconds < 1) {
      return 'AI 思考中';
    }
    if (duration.inSeconds < 60) {
      return 'AI 思考 ${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return 'AI 思考 ${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return 'AI 思考 ${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  bool _isThinkingActive(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) {
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    return sessionTurnIsThinkingStillBlocking(
      session: session,
      messages: latestGroup?.messages ?? const <ReducerMessage>[],
      manualThinkingOverride: _manualThinkingOverride,
    );
  }

  void _applyManualThinkingOverride(bool? value) {
    if (!mounted) {
      return;
    }
    _updateState(() {
      _manualThinkingOverride = value;
      if (value != true) {
        _activeResponseLocalId = null;
      }
    });
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final messages =
        sessionNotifier.getSessionMessages(widget.sessionId)?.messages ??
            const <ReducerMessage>[];
    _scheduleQueuedMessageReconciliation(session, messages);
  }

  Future<void> _showThinkingStateSheet(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    final effectiveThinking = _isThinkingActive(session, turnGroups);
    final override = _manualThinkingOverride;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 思考状态',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                override == null
                    ? '当前为自动判断：${effectiveThinking ? "思考中" : "未思考"}'
                    : '当前为手动订正：${effectiveThinking ? "思考中" : "未思考"}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.psychology_alt_rounded),
                title: const Text('标记为思考中'),
                subtitle: const Text('用于 AI 仍在执行但状态没有及时更新时。'),
                onTap: () {
                  Navigator.pop(context);
                  _applyManualThinkingOverride(true);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('标记为已结束'),
                subtitle: const Text('立即解除卡住的忙碌状态，并允许继续发送。'),
                onTap: () {
                  Navigator.pop(context);
                  _applyManualThinkingOverride(false);
                },
              ),
              if (override != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('恢复自动判断'),
                  subtitle: const Text('重新按会话事件和消息内容自动推断状态。'),
                  onTap: () {
                    Navigator.pop(context);
                    _applyManualThinkingOverride(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
