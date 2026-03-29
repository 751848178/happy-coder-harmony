part of 'sessions_screen.dart';

class _SessionsScreenViewData {
  const _SessionsScreenViewData({
    required this.body,
  });

  final Widget body;
}

_SessionsScreenViewData _buildSessionsScreenViewForState(
  _SessionsScreenState state,
) {
  final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
  final sessions = state.ref.watch(
    sessionStateProvider.select(
      (sessionState) => sessionState.when(
        initial: () => const <Session>[],
        loading: () => const <Session>[],
        ready: (sessions, _, __) => sessions.values.toList(growable: false),
        error: (_) => const <Session>[],
      ),
    ),
  );
  final settings = state.ref.watch(settingsStateProvider);
  final hideInactiveByDefault =
      state.widget.showAppBar && settings.hideInactiveSessions;
  final filteredSessions = sessions.where((session) {
    return state._matchesSessionFilters(
      session,
      selectedMachineId: state.widget.selectedMachineId,
      hideInactiveByDefault: hideInactiveByDefault,
    );
  }).toList();

  final statsBySessionId = state._resolveSessionStatsMap(
    filteredSessions,
    sessionNotifier,
  );
  final thinkingBySessionId = state._resolveSessionThinkingMap(
    filteredSessions,
    sessionNotifier,
  );

  final listContent = !state._groupingLoaded
      ? const Center(child: CircularProgressIndicator())
      : filteredSessions.isEmpty
          ? state._buildRefreshableEmptyState(
              hasSessions: sessions.isNotEmpty,
              selectedMachineName: state.widget.selectedMachineName,
            )
          : RefreshIndicator(
              onRefresh: state._refreshSessionList,
              color: AppTheme.brandColor,
              child: state._buildGroupedSessionList(
                sessions: filteredSessions,
                statsBySessionId: statsBySessionId,
                thinkingBySessionId: thinkingBySessionId,
              ),
            );

  return _SessionsScreenViewData(
    body: Column(
      children: [
        if (state.widget.showSearchBar) state._buildSearchBar(),
        state._buildGroupingToolbar(filteredSessions.isNotEmpty),
        Expanded(child: listContent),
      ],
    ),
  );
}

extension on _SessionsScreenState {
  Map<String, SessionStats> _resolveSessionStatsMap(
    List<Session> sessions,
    SessionServiceNotifier sessionNotifier,
  ) {
    final activeIds = sessions.map((session) => session.id).toSet();
    _sessionStatsCache
        .removeWhere((sessionId, _) => !activeIds.contains(sessionId));

    final statsBySessionId = <String, SessionStats>{};
    final pendingRequests = <SessionStatsSnapshotRequest>[];
    for (final session in sessions) {
      final messages = sessionNotifier.getSessionMessages(session.id)?.messages;
      final cached = _sessionStatsCache[session.id];
      if (cached != null && cached.matches(session, messages)) {
        statsBySessionId[session.id] = cached.stats;
        continue;
      }
      pendingRequests.add(
        SessionStatsSnapshotRequest(
          sessionId: session.id,
          session: session,
          messages: messages,
        ),
      );
      statsBySessionId[session.id] = SessionStatsCalculator.fromSessionPreview(
        session: session,
        messages: messages,
      );
    }
    _scheduleSessionStatsRefresh(pendingRequests, sessionNotifier);
    return statsBySessionId;
  }

  Map<String, bool> _resolveSessionThinkingMap(
    List<Session> sessions,
    SessionServiceNotifier sessionNotifier,
  ) {
    return {
      for (final session in sessions)
        session.id: sessionTurnIsThinkingStillBlocking(
          session: session,
          messages: sessionNotifier.getSessionMessages(session.id)?.messages ??
              const <ReducerMessage>[],
        ),
    };
  }

  void _scheduleSessionStatsRefresh(
    List<SessionStatsSnapshotRequest> requests,
    SessionServiceNotifier sessionNotifier,
  ) {
    final queuedRequests = requests
        .where((request) => !_sessionStatsInFlight.contains(request.sessionId))
        .toList(growable: false);
    if (queuedRequests.isEmpty) {
      return;
    }

    _sessionStatsInFlight
        .addAll(queuedRequests.map((request) => request.sessionId));
    unawaited(_refreshSessionStatsInBackground(
      queuedRequests,
      sessionNotifier,
    ));
  }

  Future<void> _refreshSessionStatsInBackground(
    List<SessionStatsSnapshotRequest> requests,
    SessionServiceNotifier sessionNotifier,
  ) async {
    try {
      final results = await computeSessionStatsBatch(requests);
      if (!mounted) {
        return;
      }

      var didUpdate = false;
      for (final request in requests) {
        final stats = results[request.sessionId];
        if (stats == null) {
          continue;
        }

        final currentSession = sessionNotifier.getSession(request.sessionId);
        final currentMessages =
            sessionNotifier.getSessionMessages(request.sessionId)?.messages;
        if (!identical(currentSession, request.session) ||
            !identical(currentMessages, request.messages)) {
          continue;
        }

        _sessionStatsCache[request.sessionId] = _SessionStatsCacheEntry(
          stats: stats,
          metadata: request.session.metadata,
          metadataVersion: request.session.metadataVersion,
          agentState: request.session.agentState,
          agentStateVersion: request.session.agentStateVersion,
          latestUsage: request.session.latestUsage,
          rawMessageCount: request.session.messages.length,
          messages: request.messages,
        );
        didUpdate = true;
      }

      if (didUpdate && mounted) {
        _rebuildView();
      }
    } finally {
      _sessionStatsInFlight
          .removeAll(requests.map((request) => request.sessionId));
    }
  }

  _SessionsScreenViewData _buildSessionsScreenView() {
    return _buildSessionsScreenViewForState(this);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      color: AppTheme.surface,
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索会话...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _updateSearchQuery(''),
                )
              : null,
          filled: true,
          fillColor: AppTheme.neutral100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
        ),
        onChanged: _updateSearchQuery,
      ),
    );
  }

  Widget _buildGroupingToolbar(bool hasSessions) {
    if (!hasSessions && !_groupingState.useCustomGroups) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd, 0, AppTheme.spacingMd, 8),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _GroupingModeButton(
                  label: '默认',
                  selected: !_groupingState.useCustomGroups,
                  onTap: () {
                    _updateGroupingState(
                      () => _groupingService.setUseCustomGroups(false),
                    );
                  },
                ),
                _GroupingModeButton(
                  label: '自定义',
                  selected: _groupingState.useCustomGroups,
                  onTap: () {
                    _updateGroupingState(
                      () => _groupingService.setUseCustomGroups(true),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_groupingState.useCustomGroups)
            _GroupingToolbarAction(
              onPressed: () => _showCreateGroupDialog(),
              icon: Icons.create_new_folder_outlined,
              label: '新建',
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedSessionList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
    required Map<String, bool> thinkingBySessionId,
  }) {
    if (_groupingState.useCustomGroups) {
      return _buildCustomGroupList(
        sessions: sessions,
        statsBySessionId: statsBySessionId,
        thinkingBySessionId: thinkingBySessionId,
      );
    }
    return _buildDefaultGroupedList(
      sessions: sessions,
      statsBySessionId: statsBySessionId,
      thinkingBySessionId: thinkingBySessionId,
    );
  }

  Widget _buildRefreshableEmptyState({
    required bool hasSessions,
    String? selectedMachineName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _refreshSessionList,
        color: AppTheme.brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: _buildEmptyState(
              hasSessions: hasSessions,
              selectedMachineName: selectedMachineName,
            ),
          ),
        ),
      ),
    );
  }
}
