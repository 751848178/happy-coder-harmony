part of 'session_screen.dart';

extension _SessionScreenStateBuild on _SessionScreenState {
  _SessionScreenSelection _watchSessionSelection() {
    return ref.watch(
      sessionStateProvider.select(
        (state) =>
            state.whenOrNull(
              ready: (sessions, sessionMessages, _) {
                final currentMessages = sessionMessages[widget.sessionId];
                return _SessionScreenSelection(
                  session: sessions[widget.sessionId],
                  messages: currentMessages?.messages,
                  hasLoadedSessions: sessions.isNotEmpty,
                  hasLoadedMessages: currentMessages?.isLoaded == true,
                  isReady: true,
                );
              },
            ) ??
            const _SessionScreenSelection.initial(),
      ),
    );
  }

  SessionStats? _resolveSessionStats(
    Session? session,
    List<ReducerMessage> messages,
  ) {
    if (session == null) {
      return null;
    }
    if (identical(_cachedStatsSession, session) &&
        identical(_cachedStatsMessages, messages)) {
      return _cachedSessionStats;
    }
    final stats = SessionStatsCalculator.fromSession(
      session: session,
      messages: messages,
    );
    _cachedStatsSession = session;
    _cachedStatsMessages = messages;
    _cachedSessionStats = stats;
    return stats;
  }

  Widget _buildSessionScreen(BuildContext context) {
    final selection = _watchSessionSelection();
    final (commandPaletteEnabled, agentInputEnterToSend) = ref.watch(
      settingsStateProvider.select(
        (s) => (s.commandPaletteEnabled, s.agentInputEnterToSend),
      ),
    );
    final session = selection.session;
    final messages = selection.messages ?? const <ReducerMessage>[];
    final showMessageLoading =
        session != null && !selection.hasLoadedMessages && messages.isEmpty;
    final socketConnected =
        ref.watch(socketStateProvider.select((state) => state.isConnected));
    final turnGroups = _resolveTurnGroups(messages);
    // Skip expensive stats computation when the overview panel is collapsed.
    // SessionStatsCalculator.fromSession() iterates every message and parses
    // text for patch summaries — O(n) per build with 264 messages.
    // When overview is collapsed (the default), this is pure waste.
    final sessionStats = _sessionOverviewCollapsed
        ? null
        : _resolveSessionStats(session, messages);
    if (messages.isNotEmpty && !_hasScrolledToLatest && !_userHasScrolledUp) {
      _scheduleScrollToLatest();
    }
    if (session != null &&
        _shouldAutoApprove(session) &&
        messages.any(
          (message) =>
              message.tool?.status == ToolCallStatus.pending &&
              !_autoApprovedToolIds.contains(message.tool!.id),
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybeAutoApprovePendingTools());
      });
    }
    final slashCommands = _resolveSlashCommands(session);
    final availableInputTemplates = _allInputTemplates();
    // Cache the thinking snapshot once per build to avoid 3 redundant
    // resolveSessionThinkingSnapshot calls, each of which copies
    // the entire message list and traverses it.
    final thinkingSnapshot = resolveSessionThinkingSnapshot(
      session: session,
      messages: messages,
    );
    final conversationBusy = _isConversationBusy(
      session,
      turnGroups,
      thinkingSnapshot: thinkingSnapshot,
    );
    final hasActiveResponseMarker = _hasEffectiveActiveResponseMarker(
      session,
      turnGroups,
      thinkingSnapshot: thinkingSnapshot,
    );
    final suppressStaleLiveState =
        _isRefreshingSessionState && !hasActiveResponseMarker;
    final effectiveConversationBusy =
        suppressStaleLiveState ? false : conversationBusy;
    final effectiveThinking =
        thinkingSnapshot.isThinking && !suppressStaleLiveState;
    final shouldKeepScreenAwake =
        session != null && (hasActiveResponseMarker || effectiveThinking);
    _updateScreenAwakePolicy(keepAwake: shouldKeepScreenAwake);
    final latestTurnMessages = turnGroups.isNotEmpty
        ? turnGroups.last.messages
        : const <ReducerMessage>[];
    final showLiveReplyBadge =
        messages.isNotEmpty && effectiveThinking && !suppressStaleLiveState;
    final hasLoadedSessions = selection.hasLoadedSessions;
    _visibleTurnGroups = turnGroups;
    // Only compute sticky turn candidates after initial load completes.
    // During loading, the message list is incomplete and the computation
    // traverses all turn groups for no visual benefit.
    _hasStickyTurnCandidates = _initialLoadComplete &&
        !_collapseAllTurns &&
        turnGroups.any(
          (group) => group.userPrompt != null && group.messages.length > 1,
        );
    if (messages.isNotEmpty &&
        (_hasStickyTurnCandidates || _stickyTurnId != null)) {
      _scheduleViewportStateRefresh();
    }
    // Skip queue reconciliation during initial load — session data is still
    // loading and reconciling against stale/empty state is wasteful.
    if (_initialLoadComplete) {
      _scheduleQueuedMessageReconciliation(session, messages);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: _buildAppBar(
          context,
          session,
          turnGroups: turnGroups,
          showOverviewToggle: true, // always show toggle when session loaded
        ),
        body: session == null && !hasLoadedSessions
            ? const Center(child: CircularProgressIndicator())
            : session == null && hasLoadedSessions
                ? _buildDeletedState()
                : Column(
                    children: [
                      if (session != null &&
                          sessionStats != null &&
                          !_sessionOverviewCollapsed)
                        _buildSessionOverview(session, sessionStats),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              // Message list — non-positioned child fills the Stack.
                              // Using Positioned.fill caused the entire area to render
                              // blank on HarmonyOS (see issue doc for details).
                              showMessageLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : messages.isEmpty
                                      ? _buildEmptyState()
                                      : _buildMessageList(
                                          messages: messages,
                                          turnGroups: turnGroups,
                                          autoApproveEnabled: session != null
                                              ? _shouldAutoApprove(session)
                                              : false,
                                        ),
                              // Sticky turn prompt — isolated rebuild via ValueNotifier.
                              if (messages.isNotEmpty && !_collapseAllTurns)
                                ValueListenableBuilder<String?>(
                                  valueListenable: _stickyTurnIdN,
                                  builder: (_, stickyTurnId, __) {
                                    if (stickyTurnId == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      key:
                                          const ValueKey('session-sticky-turn'),
                                      left: AppTheme.spacingMd,
                                      top: 8,
                                      right: showLiveReplyBadge ? 132 : 16,
                                      child: _buildStickyTurnPrompt(),
                                    );
                                  },
                                ),
                              if (showLiveReplyBadge)
                                Positioned(
                                  key: const ValueKey('session-thinking-badge'),
                                  top: 8,
                                  right: AppTheme.spacingMd,
                                  child: _buildFloatingThinkingBadge(
                                    session!,
                                    latestTurnMessages,
                                  ),
                                ),
                              // Unread indicator — isolated rebuild via ValueNotifier.
                              if (messages.isNotEmpty)
                                ValueListenableBuilder<bool>(
                                  valueListenable: _hasUnreadMessagesN,
                                  builder: (_, hasUnread, __) {
                                    if (!hasUnread) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      key: const ValueKey(
                                          'session-unread-indicator'),
                                      left: AppTheme.spacingMd,
                                      right: AppTheme.spacingMd,
                                      bottom: 112,
                                      child: Center(
                                        child: _buildNewMessageIndicator(),
                                      ),
                                    );
                                  },
                                ),
                              // Scroll actions overlay — isolated rebuild via merged ValueNotifiers.
                              if (messages.isNotEmpty)
                                ListenableBuilder(
                                  listenable: Listenable.merge([
                                    _canScrollToTopN,
                                    _canScrollToBottomN,
                                    _scrollActionsCollapsedN,
                                    _scrollActionDragDxN,
                                    _scrollActionVerticalOffsetN,
                                  ]),
                                  builder: (_, __) =>
                                      _buildScrollActionsOverlay(
                                    viewportHeight: constraints.maxHeight,
                                    session: session,
                                    turnGroups: turnGroups,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _buildInputArea(
                        session,
                        turnGroups,
                        conversationBusy: effectiveConversationBusy,
                        socketConnected: socketConnected,
                        commandPaletteEnabled: commandPaletteEnabled,
                        agentInputEnterToSend: agentInputEnterToSend,
                        slashCommands: slashCommands,
                        availableInputTemplates: availableInputTemplates,
                      ),
                    ],
                  ),
      ),
    );
  }
}
