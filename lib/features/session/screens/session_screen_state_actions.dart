part of 'session_screen.dart';

extension _SessionScreenStateActions on _SessionScreenState {
  bool _canAbortCurrentResponse(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) {
    if (session == null || !socketConnected || _isAborting || _isSending) {
      return false;
    }
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    final latestMessages = latestGroup?.messages ?? const <ReducerMessage>[];
    final thinking = sessionTurnIsThinkingStillBlocking(
      session: session,
      messages: latestMessages,
      manualThinkingOverride: _manualThinkingOverride,
    );
    final hasActiveResponseMarker =
        _hasEffectiveActiveResponseMarker(session, turnGroups);
    return thinking ||
        sessionTurnHasBlockingToolWork(latestMessages) ||
        hasActiveResponseMarker;
  }

  Future<void> _handleAbortAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) async {
    if (!_canAbortCurrentResponse(
      session,
      turnGroups,
      socketConnected: socketConnected,
    )) {
      return;
    }

    _updateState(() => _isAborting = true);
    try {
      await ref.read(sessionStateProvider.notifier).abortSession(
            sessionId: widget.sessionId,
          );
      if (mounted) {
        _updateState(() {
          _awaitingAbortRemoteSettle = true;
        });
      }
      await _reconcileQueuedMessageState();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已向 PC 发送停止请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('停止失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        _updateState(() => _isAborting = false);
      }
    }
  }

  Future<void> _maybeAutoApprovePendingTools() async {
    if (!ref.read(socketStateProvider).isConnected) {
      return;
    }
    final session =
        ref.read(sessionStateProvider.notifier).getSession(widget.sessionId);
    if (session == null || !_shouldAutoApprove(session)) {
      return;
    }
    final messages = ref
            .read(sessionStateProvider.notifier)
            .getSessionMessages(widget.sessionId)
            ?.messages ??
        const <ReducerMessage>[];
    final pendingToolIds = messages
        .where(
          (message) =>
              message.tool?.status == ToolCallStatus.pending &&
              !_toolActionsInFlight.contains(message.tool!.id) &&
              !_autoApprovedToolIds.contains(message.tool!.id),
        )
        .map((message) => message.tool!.id)
        .toList();
    for (final toolId in pendingToolIds) {
      _autoApprovedToolIds.add(toolId);
      await _approveToolCall(toolId, showError: false);
    }
  }

  void _showRenameDialog(Session? session) {
    if (session == null) {
      return;
    }
    final controller = TextEditingController(text: session.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改会话名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的会话名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renameSession(controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(String alias) async {
    try {
      await ref.read(sessionStateProvider.notifier).renameSession(
            sessionId: widget.sessionId,
            alias: alias,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会话名称已更新'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新会话名称失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleSendAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups,
  ) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (_isConversationBusy(session, turnGroups)) {
      _messageController.clear();
      _messageFocusNode.requestFocus();
      await _enqueueComposerMessage(text);
      return;
    }

    _messageController.clear();
    _messageFocusNode.requestFocus();
    await _dispatchMessage(text);
  }

  Future<bool> _dispatchMessage(
    String text, {
    bool restoreComposerOnError = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final localId = _createLocalMessageId();
    _updateState(() {
      _isSending = true;
      _activeResponseLocalId = localId;
      _manualThinkingOverride = null;
      _awaitingAbortRemoteSettle = false;
    });

    try {
      final sendFuture = ref.read(sessionStateProvider.notifier).sendMessage(
            sessionId: widget.sessionId,
            content: trimmed,
            localId: localId,
          );
      _scheduleScrollToLatest(animate: true, force: true);
      await sendFuture;
      _scrollToBottom();
      return true;
    } catch (e) {
      if (_activeResponseLocalId == localId && mounted) {
        _updateState(() {
          _activeResponseLocalId = null;
        });
      }
      if (restoreComposerOnError) {
        _setComposerText(trimmed);
        _messageFocusNode.requestFocus();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        _updateState(() => _isSending = false);
      }
    }
  }
}
