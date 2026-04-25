part of '../session_detail.dart';

extension _SessionScreenStateLoad on _SessionScreenState {
  Future<void> _loadNonCriticalUiData() async {
    final results = await Future.wait([
      _inputTemplateService.loadTemplates(),
      _uiStateService.get(widget.sessionId),
    ]);
    if (!mounted) {
      return;
    }
    final templates = results[0] as List<SessionInputTemplate>;
    final uiState = results[1] as SessionUiState;
    _customInputTemplatesN.value =
        List<SessionInputTemplate>.unmodifiable(templates);
    _sessionOverviewCollapsedN.value = uiState.overviewCollapsed;
    _updateState(() {
      _collapseAllTurns = uiState.collapseAllTurns;
      _expandedTurnIds
        ..clear()
        ..addAll(uiState.expandedTurnIds);
    });
  }

  void _restoreComposerDraft(
    Session? session, {
    bool force = false,
  }) {
    final draft = session?.draft ?? '';
    if (!force && _messageController.text.isNotEmpty) {
      return;
    }
    if (_messageController.text == draft) {
      return;
    }
    _setComposerText(draft);
  }

  Future<void> _persistSessionUiState() {
    return _uiStateService.update(
      widget.sessionId,
      overviewCollapsed: _sessionOverviewCollapsed,
      collapseAllTurns: _collapseAllTurns,
      expandedTurnIds: Set<String>.from(_expandedTurnIds),
    );
  }

  Future<void> _loadQueuedComposerMessages() async {
    final queuedMessages = await _composerQueueService.get(widget.sessionId);
    if (!mounted) {
      return;
    }
    _queuedMessagesN.value = queuedMessages;
  }

  Future<void> _storeQueuedComposerMessages(
    List<QueuedComposerMessage> queuedMessages,
  ) async {
    if (mounted) {
      _queuedMessagesN.value = List<QueuedComposerMessage>.from(queuedMessages);
    }
    try {
      await _composerQueueService.replace(widget.sessionId, queuedMessages);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新待发送消息失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _loadSessionData() => _loadCoordinator.loadSessionData();
}
