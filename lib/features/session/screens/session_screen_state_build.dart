part of 'session_screen.dart';

extension _SessionScreenStateBuild on _SessionScreenState {
  _SessionScreenSelection _watchSessionSelection() {
    return ref.watch(
      sessionStateProvider.select(
        (state) =>
            state.whenOrNull(
              ready: (sessions, _, __) {
                return _SessionScreenSelection(
                  session: sessions[widget.sessionId],
                  hasLoadedSessions: sessions.isNotEmpty,
                  isReady: true,
                );
              },
            ) ??
            const _SessionScreenSelection.initial(),
      ),
    );
  }

  /// Session-level build — only rebuilds when session metadata changes
  /// (title, active, thinking, draft, etc.). Does NOT rebuild when only
  /// messages change — message-driven rebuilds are isolated in
  /// [_buildSessionBody] via [ListenableBuilder].
  Widget _buildSessionScreen(BuildContext context) {
    final selection = _watchSessionSelection();
    final (commandPaletteEnabled, agentInputEnterToSend) = ref.watch(
      settingsStateProvider.select(
        (s) => (s.commandPaletteEnabled, s.agentInputEnterToSend),
      ),
    );
    final session = selection.session;
    final socketConnected =
        ref.watch(socketStateProvider.select((state) => state.isConnected));
    final hasLoadedSessions = selection.hasLoadedSessions;
    final slashCommands = _resolveSlashCommands(session);

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
          showOverviewToggle: true,
        ),
        body: session == null && !hasLoadedSessions
            ? const Center(child: CircularProgressIndicator())
            : session == null && hasLoadedSessions
                ? _buildDeletedState()
                : _buildSessionBody(
                    session: session!,
                    commandPaletteEnabled: commandPaletteEnabled,
                    agentInputEnterToSend: agentInputEnterToSend,
                    socketConnected: socketConnected,
                    slashCommands: slashCommands,
                  ),
      ),
    );
  }

  /// Message-dependent body — rebuilds ONLY when [_messageViewStateN]
  /// changes, independently of the AppBar and Scaffold.
  /// This isolates message-driven rebuilds (streaming, loading) from
  /// session-level rebuilds (title change, active status, etc.).
  Widget _buildSessionBody({
    required Session session,
    required bool commandPaletteEnabled,
    required bool agentInputEnterToSend,
    required bool socketConnected,
    required List<_SlashCommandItem> slashCommands,
  }) {
    return ListenableBuilder(
      listenable: _messageViewStateN,
      builder: (context, _) {
        final bodyState = _bodyPresenter.resolve(
          session: session,
          messages: _messages,
          hasLoadedMessages: _hasLoadedMessages,
        );
        return _SessionScreenBodyEffects(
          bodyState: bodyState,
          hasScrolledToLatest: _hasScrolledToLatest,
          hasNewerMessages: _hasNewerMessages,
          userHasScrolledUp: _userHasScrolledUp,
          initialLoadComplete: _initialLoadComplete,
          autoApproveEnabled: _shouldAutoApprove(session),
          stickyTurnId: _stickyTurnId,
          onVisibleTurnGroupsChanged: (turnGroups) {
            _visibleTurnGroups = turnGroups;
          },
          onScheduleScrollToLatest: _scheduleScrollToLatest,
          onMaybeAutoApprovePendingTools: _maybeAutoApprovePendingTools,
          onUpdateScreenAwakePolicy: (keepAwake) {
            _updateScreenAwakePolicy(keepAwake: keepAwake);
          },
          onScheduleViewportStateRefresh: _scheduleViewportStateRefresh,
          onScheduleQueuedMessageReconciliation: () {
            _scheduleQueuedMessageReconciliation(session, bodyState.messages);
          },
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _sessionOverviewCollapsedN,
                builder: (_, collapsed, __) {
                  if (collapsed || bodyState.sessionStats == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildSessionOverview(session, bodyState.sessionStats!);
                },
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      bodyState.showMessageLoading
                          ? const Center(child: CircularProgressIndicator())
                          : bodyState.messages.isEmpty
                              ? _buildEmptyState()
                              : ValueListenableBuilder<bool>(
                                  valueListenable: _messageViewportReadyN,
                                  builder: (_, viewportReady, __) {
                                    final list = _buildMessageList(
                                      messages: bodyState.messages,
                                      turnGroups: bodyState.turnGroups,
                                      autoApproveEnabled:
                                          _shouldAutoApprove(session),
                                    );
                                    final shouldRevealList = viewportReady ||
                                        _hasScrolledToLatest ||
                                        _userHasScrolledUp ||
                                        bodyState.messages.isEmpty;
                                    return Stack(
                                      children: [
                                        IgnorePointer(
                                          ignoring: !shouldRevealList,
                                          child: AnimatedOpacity(
                                            opacity: shouldRevealList ? 1 : 0,
                                            duration: const Duration(
                                              milliseconds: 80,
                                            ),
                                            child: list,
                                          ),
                                        ),
                                        if (!shouldRevealList)
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                      if (bodyState.messages.isNotEmpty && !_collapseAllTurns)
                        ValueListenableBuilder<String?>(
                          valueListenable: _stickyTurnIdN,
                          builder: (_, stickyTurnId, __) {
                            if (stickyTurnId == null) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              key: const ValueKey('session-sticky-turn'),
                              left: AppTheme.spacingMd,
                              top: 8,
                              right: bodyState.showLiveReplyBadge ? 132 : 16,
                              child: _buildStickyTurnPrompt(),
                            );
                          },
                        ),
                      if (bodyState.showLiveReplyBadge)
                        Positioned(
                          key: const ValueKey('session-thinking-badge'),
                          top: 8,
                          right: AppTheme.spacingMd,
                          child: _buildFloatingThinkingBadge(
                            session,
                            bodyState.latestTurnMessages,
                          ),
                        ),
                      if (bodyState.messages.isNotEmpty)
                        ValueListenableBuilder<bool>(
                          valueListenable: _hasUnreadMessagesN,
                          builder: (_, hasUnread, __) {
                            if (!hasUnread) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              key: const ValueKey('session-unread-indicator'),
                              left: AppTheme.spacingMd,
                              right: AppTheme.spacingMd,
                              bottom: 112,
                              child: Center(
                                child: _buildNewMessageIndicator(),
                              ),
                            );
                          },
                        ),
                      if (bodyState.messages.isNotEmpty)
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _canScrollToTopN,
                            _canScrollToBottomN,
                            _scrollActionsCollapsedN,
                            _scrollActionDragDxN,
                            _scrollActionVerticalOffsetN,
                          ]),
                          builder: (_, __) => _buildScrollActionsOverlay(
                            viewportHeight: constraints.maxHeight,
                            session: session,
                            turnGroups: bodyState.turnGroups,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildInputArea(
                session,
                bodyState.turnGroups,
                conversationBusy: bodyState.effectiveConversationBusy,
                socketConnected: socketConnected,
                commandPaletteEnabled: commandPaletteEnabled,
                agentInputEnterToSend: agentInputEnterToSend,
                slashCommands: slashCommands,
              ),
            ],
          ),
        );
      },
    );
  }
}
