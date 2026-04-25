part of 'sessions_screen.dart';

_SessionsScreenViewData _buildSessionsScreenViewForState(
  _SessionsScreenState state,
) {
  final sessionNotifier = state.ref.read(sessionStateProvider.notifier);
  final layoutSelection = state.ref.watch(
    sessionStateProvider.select(
      (sessionState) =>
          sessionState.whenOrNull<_SessionsScreenLayoutSelection>(
            ready: (sessions, _, __) =>
                _SessionsScreenLayoutSelection.fromSessions(sessions.values),
          ) ??
          const _SessionsScreenLayoutSelection.empty(),
    ),
  );
  final sessions = layoutSelection.sessions
      .map((layoutSession) => sessionNotifier.getSession(layoutSession.id))
      .whereType<Session>()
      .toList(growable: false);
  final hideInactiveByDefault = state.widget.showAppBar &&
      state.ref.watch(
        settingsStateProvider.select((s) => s.hideInactiveSessions),
      );

  return _SessionsScreenViewData(
    body: Column(
      children: [
        if (state.widget.showSearchBar)
          ValueListenableBuilder<String>(
            valueListenable: state._searchQueryN,
            builder: (_, __, ___) => state._buildSearchBar(),
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              state._searchQueryN,
              state._showActiveOnlyN,
              state._groupingStateN,
              state._groupingLoadedN,
            ]),
            builder: (_, __) {
              final filteredSessions = sessions
                  .where(
                    (session) => state._matchesSessionFilters(
                      session,
                      selectedMachineId: state.widget.selectedMachineId,
                      hideInactiveByDefault: hideInactiveByDefault,
                    ),
                  )
                  .toList(growable: false);

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
                          ),
                        );

              return Column(
                children: [
                  state._buildGroupingToolbar(filteredSessions.isNotEmpty),
                  Expanded(child: listContent),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

extension on _SessionsScreenState {
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
  }) {
    if (_groupingState.useCustomGroups) {
      return _buildCustomGroupList(sessions: sessions);
    }
    return _buildDefaultGroupedList(sessions: sessions);
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
