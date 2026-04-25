part of '../session_detail.dart';

class _SessionScreenCommandController {
  _SessionScreenCommandController(this._state);

  final _SessionScreenState _state;

  bool canAbortCurrentResponse(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) {
    if (session == null ||
        !socketConnected ||
        _state._isAborting ||
        _state._isSending) {
      return false;
    }
    final latestGroup = turnGroups.isNotEmpty ? turnGroups.last : null;
    final latestMessages = latestGroup?.messages ?? const <ReducerMessage>[];
    final thinking = sessionTurnIsThinkingStillBlocking(
      session: session,
      messages: latestMessages,
      manualThinkingOverride: _state._manualThinkingOverride,
    );
    final hasActiveResponseMarker =
        _state._hasEffectiveActiveResponseMarker(session, turnGroups);
    return thinking ||
        sessionTurnHasBlockingToolWork(latestMessages) ||
        hasActiveResponseMarker;
  }

  Future<void> handleAbortAction(
    Session? session,
    List<_MessageTurnGroup> turnGroups, {
    required bool socketConnected,
  }) async {
    if (!canAbortCurrentResponse(
      session,
      turnGroups,
      socketConnected: socketConnected,
    )) {
      return;
    }

    _state._isAbortingN.value = true;
    try {
      await _state.ref.read(sessionStateProvider.notifier).abortSession(
            sessionId: _state.widget.sessionId,
          );
      if (_state.mounted) {
        _state._updateState(() {
          _state._awaitingAbortRemoteSettle = true;
        });
      }
      await _state._reconcileQueuedMessageState();
      if (!_state.mounted) {
        return;
      }
      ScaffoldMessenger.of(_state.context).showSnackBar(
        const SnackBar(
          content: Text('已向 PC 发送停止请求'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!_state.mounted) {
        return;
      }
      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(
          content: Text('停止失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (_state.mounted) {
        _state._isAbortingN.value = false;
      }
    }
  }

  Future<void> maybeAutoApprovePendingTools() async {
    if (!_state.ref.read(socketStateProvider).isConnected) {
      return;
    }
    final session = _state.ref
        .read(sessionStateProvider.notifier)
        .getSession(_state.widget.sessionId);
    if (session == null || !_state._shouldAutoApprove(session)) {
      return;
    }
    final messages = _state.ref
            .read(sessionStateProvider.notifier)
            .getSessionMessages(_state.widget.sessionId)
            ?.messages ??
        const <ReducerMessage>[];
    final pendingToolIds = messages
        .where(
          (message) =>
              message.tool?.status == ToolCallStatus.pending &&
              !_state._toolActionsInFlight.contains(message.tool!.id) &&
              !_state._autoApprovedToolIds.contains(message.tool!.id),
        )
        .map((message) => message.tool!.id)
        .toList();
    for (final toolId in pendingToolIds) {
      _state._autoApprovedToolIds.add(toolId);
      await _state._approveToolCall(toolId, showError: false);
    }
  }

  Future<void> renameSession(String alias) async {
    try {
      await _state.ref.read(sessionStateProvider.notifier).renameSession(
            sessionId: _state.widget.sessionId,
            alias: alias,
          );
      if (!_state.mounted) {
        return;
      }
      ScaffoldMessenger.of(_state.context).showSnackBar(
        const SnackBar(
          content: Text('会话名称已更新'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!_state.mounted) {
        return;
      }
      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(
          content: Text('更新会话名称失败: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<bool> dispatchMessage(
    String text, {
    bool restoreComposerOnError = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final localId = _state._createLocalMessageId();
    _state._updateState(() {
      _state._activeResponseLocalId = localId;
      _state._manualThinkingOverride = null;
      _state._awaitingAbortRemoteSettle = false;
    });
    _state._isSendingN.value = true;

    try {
      final sendFuture =
          _state.ref.read(sessionStateProvider.notifier).sendMessage(
                sessionId: _state.widget.sessionId,
                content: trimmed,
                localId: localId,
              );
      _state._scheduleScrollToLatest(animate: true, force: true);
      await sendFuture;
      return true;
    } catch (error) {
      if (_state._activeResponseLocalId == localId && _state.mounted) {
        _state._updateState(() {
          _state._activeResponseLocalId = null;
        });
      }
      if (restoreComposerOnError) {
        _state._setComposerText(trimmed);
        _state._messageFocusNode.requestFocus();
      }
      if (_state.mounted) {
        ScaffoldMessenger.of(_state.context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    } finally {
      if (_state.mounted) {
        _state._isSendingN.value = false;
      }
    }
  }
}
