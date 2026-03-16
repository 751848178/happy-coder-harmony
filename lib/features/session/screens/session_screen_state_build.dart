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
    final hasLoadedSessions = sessionNotifier.sessions.isNotEmpty;
    _visibleTurnGroups = turnGroups;
    if (messages.isNotEmpty) {
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
                                left: AppTheme.spacingMd,
                                top: 8,
                                right: showLiveReplyBadge ? 132 : 16,
                                child: _buildStickyTurnPrompt(),
                              ),
                            if (showLiveReplyBadge)
                              Positioned(
                                top: 8,
                                right: AppTheme.spacingMd,
                                child: _buildFloatingThinkingBadge(session!),
                              ),
                            if (messages.isNotEmpty && _hasUnreadMessages)
                              Positioned(
                                left: AppTheme.spacingMd,
                                right: AppTheme.spacingMd,
                                bottom: 76,
                                child: Center(
                                  child: _buildNewMessageIndicator(),
                                ),
                              ),
                            if (messages.isNotEmpty)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppTheme.spacingMd,
                                    bottom: 12,
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
