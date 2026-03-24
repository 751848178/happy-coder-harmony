part of 'session_screen.dart';

extension _SessionScreenStateBuild on _SessionScreenState {
  Widget _buildSessionScreen(BuildContext context) {
    ref.watch(sessionStateProvider);
    final settings = ref.watch(settingsStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final sessionMessages =
        sessionNotifier.getSessionMessages(widget.sessionId);
    final messages = sessionMessages?.messages ?? [];
    final turnGroups = _MessageTurnGroup.build(messages);
    final sessionStats = session == null
        ? null
        : SessionStatsCalculator.fromSession(
            session: session,
            messages: messages,
          );
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
    final visibleSlashCommands = _visibleSlashCommands(
      session,
      settings.commandPaletteEnabled,
    );
    final visibleInputTemplates = _visibleInputTemplates();
    final conversationBusy = _isConversationBusy(session, turnGroups);
    final suppressStaleLiveState =
        _isRefreshingSessionState && _activeResponseLocalId == null;
    final effectiveConversationBusy =
        suppressStaleLiveState ? false : conversationBusy;
    final showLiveReplyBadge = messages.isNotEmpty &&
        session?.thinking == true &&
        !suppressStaleLiveState;
    final messageViewportReady = messages.isEmpty || _hasScrolledToLatest;
    final hasLoadedSessions = sessionNotifier.sessions.isNotEmpty;
    _visibleTurnGroups = turnGroups;
    if (messageViewportReady && messages.isNotEmpty) {
      _scheduleViewportStateRefresh();
    }
    _scheduleQueuedMessageReconciliation();

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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: messages.isEmpty
                                  ? _buildEmptyState()
                                  : IgnorePointer(
                                      ignoring: !messageViewportReady,
                                      child: Opacity(
                                        opacity: messageViewportReady ? 1 : 0,
                                        child: _buildMessageList(
                                          messages: messages,
                                          turnGroups: turnGroups,
                                          autoApproveEnabled: session != null
                                              ? _shouldAutoApprove(session)
                                              : false,
                                        ),
                                      ),
                                    ),
                            ),
                            if (messageViewportReady &&
                                messages.isNotEmpty &&
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
                                child: _buildFloatingThinkingBadge(session!),
                              ),
                            if (messageViewportReady &&
                                messages.isNotEmpty &&
                                _hasUnreadMessages)
                              Positioned(
                                key: const ValueKey('session-unread-indicator'),
                                left: AppTheme.spacingMd,
                                right: AppTheme.spacingMd,
                                bottom: 112,
                                child: Center(
                                  child: _buildNewMessageIndicator(),
                                ),
                              ),
                            if (messageViewportReady && messages.isNotEmpty)
                              Align(
                                key: const ValueKey('session-scroll-actions'),
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppTheme.spacingMd,
                                    bottom: 20,
                                  ),
                                  child: _buildScrollActions(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildInputArea(
                        session,
                        turnGroups,
                        conversationBusy: effectiveConversationBusy,
                        settings: settings,
                        slashCommands: slashCommands,
                        visibleSlashCommands: visibleSlashCommands,
                        visibleInputTemplates: visibleInputTemplates,
                      ),
                    ],
                  ),
      ),
    );
  }
}
