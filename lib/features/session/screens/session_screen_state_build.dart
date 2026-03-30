part of 'session_screen.dart';

extension _SessionScreenStateBuild on _SessionScreenState {
  _SessionScreenSelection _watchSessionSelection() {
    return ref.watch(
      sessionStateProvider.select(
        (state) =>
            state.whenOrNull(
              ready: (sessions, sessionMessages, _) => _SessionScreenSelection(
                session: sessions[widget.sessionId],
                messages: sessionMessages[widget.sessionId]?.messages,
                hasLoadedSessions: sessions.isNotEmpty,
                isReady: true,
              ),
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
    final settings = ref.watch(settingsStateProvider);
    final session = selection.session;
    final messages = selection.messages ?? const <ReducerMessage>[];
    final socketConnected =
        ref.watch(socketStateProvider.select((state) => state.isConnected));
    final turnGroups = _resolveTurnGroups(messages);
    final sessionStats = _resolveSessionStats(session, messages);
    if (messages.isNotEmpty && !_hasScrolledToLatest) {
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
    final conversationBusy = _isConversationBusy(session, turnGroups);
    final hasActiveResponseMarker =
        _hasEffectiveActiveResponseMarker(session, turnGroups);
    final suppressStaleLiveState =
        _isRefreshingSessionState && !hasActiveResponseMarker;
    final effectiveConversationBusy =
        suppressStaleLiveState ? false : conversationBusy;
    final effectiveThinking = _isThinkingActive(session, turnGroups);
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
    _hasStickyTurnCandidates = !_collapseAllTurns &&
        turnGroups.any(
          (group) => group.userPrompt != null && group.messages.length > 1,
        );
    if (messages.isNotEmpty &&
        (_hasStickyTurnCandidates || _stickyTurnId != null)) {
      _scheduleViewportStateRefresh();
    }
    _scheduleQueuedMessageReconciliation(session, messages);

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
          showOverviewToggle: sessionStats != null,
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
                              Positioned.fill(
                                child: messages.isEmpty
                                    ? _buildEmptyState()
                                    : _buildMessageList(
                                        messages: messages,
                                        turnGroups: turnGroups,
                                        autoApproveEnabled: session != null
                                            ? _shouldAutoApprove(session)
                                            : false,
                                      ),
                              ),
                              if (messages.isNotEmpty &&
                                  _stickyTurnId != null &&
                                  !_collapseAllTurns)
                                Positioned(
                                  key: const ValueKey('session-sticky-turn'),
                                  left: AppTheme.spacingMd,
                                  top: 8,
                                  right: showLiveReplyBadge ? 132 : 16,
                                  child: _buildStickyTurnPrompt(),
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
                              if (messages.isNotEmpty && _hasUnreadMessages)
                                Positioned(
                                  key: const ValueKey(
                                      'session-unread-indicator'),
                                  left: AppTheme.spacingMd,
                                  right: AppTheme.spacingMd,
                                  bottom: 112,
                                  child: Center(
                                    child: _buildNewMessageIndicator(),
                                  ),
                                ),
                              if (messages.isNotEmpty)
                                _buildScrollActionsOverlay(
                                  viewportHeight: constraints.maxHeight,
                                  session: session,
                                  turnGroups: turnGroups,
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
                        settings: settings,
                        slashCommands: slashCommands,
                        availableInputTemplates: availableInputTemplates,
                      ),
                    ],
                  ),
      ),
    );
  }
}
