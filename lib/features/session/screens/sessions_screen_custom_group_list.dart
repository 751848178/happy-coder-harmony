part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  Widget _buildCustomGroupList({
    required List<Session> sessions,
  }) {
    final unavailableSessions =
        sessions.where(_isSessionUnavailable).toList(growable: false);
    final availableSessions =
        sessions.where((session) => !_isSessionUnavailable(session)).toList();
    final sessionMap = {
      for (final session in availableSessions) session.id: session,
    };
    final sections = <Widget>[
      for (final group in _groupingState.groups)
        _buildCustomGroupSection(
          group: group,
          sessionMap: sessionMap,
        ),
      _buildUngroupedSection(sessions: availableSessions),
      if (unavailableSessions.isNotEmpty)
        _buildUnavailableCustomGroupSection(
          sessions: unavailableSessions,
        ),
    ];

    if (_groupingState.groups.isEmpty &&
        availableSessions.isEmpty &&
        unavailableSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_copy_outlined,
              size: 56,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有自定义分组',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral800,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('创建第一个分组'),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: sections,
    );
  }

  Widget _buildUnavailableCustomGroupSection({
    required List<Session> sessions,
  }) {
    final orderedSessions = sessions.toList(growable: false)
      ..sort(compareSessionsByStableListOrder);
    return _SessionsGroupSection(
      header: _SessionSectionHeader(
        title: SessionsScreen.unavailableGroupLabel,
        count: orderedSessions.length,
        collapsed: _isDefaultGroupCollapsed(
          SessionsScreen.unavailableGroupLabel,
          defaultCollapsed: true,
        ),
        onTap: () => _toggleDefaultGroup(
          SessionsScreen.unavailableGroupLabel,
          defaultCollapsed: true,
        ),
      ),
      collapsed: _isDefaultGroupCollapsed(
        SessionsScreen.unavailableGroupLabel,
        defaultCollapsed: true,
      ),
      children: [
        for (final session in orderedSessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionListItem(
              key: ValueKey(session.id),
              session: session,
              onTap: () => _openSession(session),
              onDelete: () => _deleteSession(session),
              onMove: () => _showMoveSessionSheet(session),
              onLongPress: () => _showMoveSessionSheet(session),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomGroupSection({
    required SessionGroup group,
    required Map<String, Session> sessionMap,
  }) {
    final groupedSessions = orderSessionsByStoredIds(
      group.sessionIds,
      sessionMap,
    );
    return _SessionsGroupSection(
      header: _SessionSectionHeader(
        title: group.name,
        count: groupedSessions.length,
        collapsed: group.collapsed,
        trailingMenu: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          onSelected: (value) {
            if (value == 'rename') {
              _showRenameGroupDialog(group);
            } else if (value == 'delete') {
              _deleteGroup(group);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('重命名')),
            PopupMenuItem(value: 'delete', child: Text('删除分组')),
          ],
          child: const Icon(Icons.more_horiz_rounded),
        ),
        onTap: () {
          _updateGroupingState(
            () => _groupingService.toggleGroupCollapsed(group.id),
          );
        },
      ),
      collapsed: group.collapsed,
      children: groupedSessions.isEmpty
          ? const [_EmptyGroupCard(text: '这个分组还没有会话，长按任意会话后可移动到这里。')]
          : [
              for (final session in groupedSessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SessionListItem(
                    key: ValueKey(session.id),
                    session: session,
                    onTap: () => _openSession(session),
                    onDelete: () => _deleteSession(session),
                    onMove: () => _showMoveSessionSheet(session),
                    onLongPress: () => _showMoveSessionSheet(session),
                  ),
                ),
            ],
    );
  }

  Widget _buildUngroupedSection({
    required List<Session> sessions,
  }) {
    final groupedIds =
        _groupingState.groups.expand((group) => group.sessionIds).toSet();
    final ungroupedSessions = sessions
        .where((session) => !groupedIds.contains(session.id))
        .toList()
      ..sort(compareSessionsByStableListOrder);
    return _SessionsGroupSection(
      header: _SessionSectionHeader(
        title: '未分组',
        count: ungroupedSessions.length,
        collapsed: _groupingState.ungroupedCollapsed,
        onTap: () {
          _updateGroupingState(
            () => _groupingService.toggleUngroupedCollapsed(),
          );
        },
      ),
      collapsed: _groupingState.ungroupedCollapsed,
      children: ungroupedSessions.isEmpty
          ? const [_EmptyGroupCard(text: '当前没有未分组会话。')]
          : [
              for (final session in ungroupedSessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SessionListItem(
                    key: ValueKey(session.id),
                    session: session,
                    onTap: () => _openSession(session),
                    onDelete: () => _deleteSession(session),
                    onMove: () => _showMoveSessionSheet(session),
                    onLongPress: () => _showMoveSessionSheet(session),
                  ),
                ),
            ],
    );
  }
}
