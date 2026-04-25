part of '../session_detail.dart';

extension _SessionScreenMessageInteractions on _SessionScreenState {
  void _setMessageInteractionsEnabled(bool enabled) {
    if (_messageInteractionsEnabledN.value == enabled) {
      return;
    }
    _messageInteractionsEnabledN.value = enabled;
  }

  void _pauseMessageInteractions() {
    _messageInteractionIdleDebounce?.cancel();
    _messageInteractionIdleDebounce = null;
    _setMessageInteractionsEnabled(false);
  }

  void _scheduleMessageInteractionsIdleEnable() {
    _messageInteractionIdleDebounce?.cancel();
    _messageInteractionIdleDebounce = Timer(
      _sessionMessageInteractionIdleDelay,
      () {
        if (!mounted ||
            !_messageViewportReady ||
            !_hasLoadedMessages ||
            _messages.isEmpty ||
            !_scrollController.hasClients ||
            _viewportController.programmaticScrollActivity != 0 ||
            _isLoadingOlderMessages ||
            _isLoadingNewerMessages) {
          return;
        }
        final position = _scrollController.effectivePosition;
        if (position.isScrollingNotifier.value) {
          _scheduleMessageInteractionsIdleEnable();
          return;
        }
        _setMessageInteractionsEnabled(true);
      },
    );
  }

  void _markMessageListScrollActivity() {
    _pauseMessageInteractions();
    _scheduleMessageInteractionsIdleEnable();
  }

  void _registerMessageRowContext(String rowId, BuildContext context) {
    final previousContext = _messageRowContexts[rowId];
    if (previousContext != null && !identical(previousContext, context)) {
      Logger.info(
        '[SessionAnchor] rebind session=${widget.sessionId} '
        'row=$rowId ${_debugMessageWindowSummary()}',
      );
    }
    _messageRowContexts[rowId] = context;
  }

  void _unregisterMessageRowContext(String rowId, BuildContext context) {
    final currentContext = _messageRowContexts[rowId];
    if (currentContext != null && !identical(currentContext, context)) {
      Logger.info(
        '[SessionAnchor] stale-detach session=${widget.sessionId} '
        'row=$rowId ${_debugMessageWindowSummary()}',
      );
    }
    if (identical(currentContext, context)) {
      _messageRowContexts.remove(rowId);
    }
  }

  BuildContext? _messageRowContext(String rowId) {
    return _messageRowContexts[rowId];
  }

  BuildContext? _turnSectionContext(String turnId) {
    final rowId = _turnSectionRowIds[turnId];
    if (rowId == null) {
      return null;
    }
    return _messageRowContext(rowId);
  }

  BuildContext? _turnReplyContext(String turnId) {
    final rowId = _turnReplyRowIds[turnId];
    if (rowId == null) {
      return null;
    }
    return _messageRowContext(rowId);
  }

  String? _resolveTurnReplyMessageId(_MessageTurnGroup group) {
    if (group.messages.isEmpty) {
      return null;
    }
    final promptId = group.userPrompt?.id;
    for (final message in group.messages) {
      if (message.id != promptId) {
        return message.id;
      }
    }
    return null;
  }

  void _pruneMessageRenderCaches(List<ReducerMessage> messages) {
    final activeTurnGroups = _bodyPresenter.resolveTurnGroups(messages);
    final activeFlatItems = _bodyPresenter.resolveFlatItems(activeTurnGroups);
    final activeRowIds = activeFlatItems.map((item) => item.renderId).toSet();
    final rowIdsByMessage = <ReducerMessage, String>{
      for (final item in activeFlatItems) item.message: item.renderId,
    };
    final activeToolIds =
        messages.map((message) => message.tool?.id).whereType<String>().toSet();
    _messageRowContexts.removeWhere(
      (rowId, _) => !activeRowIds.contains(rowId),
    );
    // Safety cap: if the context registry grows beyond 3x the active message
    // count (e.g. due to a race between KeepAlive registration and prune),
    // evict the oldest entries to bound memory usage.
    if (_messageRowContexts.length > activeRowIds.length * 3 &&
        _messageRowContexts.length > 200) {
      final excess = _messageRowContexts.length - activeRowIds.length;
      var evicted = 0;
      final keysToEvict = _messageRowContexts.keys
          .where((id) => !activeRowIds.contains(id))
          .toList(growable: false);
      for (final key in keysToEvict) {
        if (evicted >= excess) break;
        _messageRowContexts.remove(key);
        evicted++;
      }
    }
    final staleToolIds = _toolActionPendingNotifiers.keys
        .where((toolId) => !activeToolIds.contains(toolId))
        .toList(growable: false);
    for (final toolId in staleToolIds) {
      _toolActionPendingNotifiers.remove(toolId)?.dispose();
      _toolActionsInFlight.remove(toolId);
    }
    // Only rebuild turn-group context maps when turn groups actually changed.
    // During streaming updates the turn groups are typically append-only and
    // the cached groups are identical, so resolveTurnGroups returns the same
    // list.  Skip the clear+rebuild in that case to avoid O(groups) work on
    // every message sync.
    if (!identical(activeTurnGroups, _cachedPruneTurnGroups)) {
      _cachedPruneTurnGroups = activeTurnGroups;
      _turnSectionRowIds
        ..clear()
        ..addEntries(
          activeTurnGroups.where((group) => group.messages.isNotEmpty).map(
                (group) => MapEntry(
                  group.id,
                  rowIdsByMessage[group.messages.last] ??
                      group.messages.last.id,
                ),
              ),
        );
      _turnReplyRowIds.clear();
      for (final group in activeTurnGroups) {
        final replyMessageId = _resolveTurnReplyMessageId(group);
        if (replyMessageId == null) {
          continue;
        }
        final replyMessage = group.messages.firstWhere(
          (message) => message.id == replyMessageId,
          orElse: () => group.messages.last,
        );
        _turnReplyRowIds[group.id] =
            rowIdsByMessage[replyMessage] ?? replyMessage.id;
      }
    }
  }
}
