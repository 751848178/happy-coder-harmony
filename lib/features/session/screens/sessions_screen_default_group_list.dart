part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  Widget _buildDefaultGroupedList({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final availableSessions = sessions
        .where((session) => !_isSessionUnavailable(session))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final unavailableSessions = sessions.where(_isSessionUnavailable).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final sessionMap = {for (final session in sessions) session.id: session};
    final groups = DateGrouper.groupByDate(
      availableSessions
          .map(
            (session) => SessionHistoryItem(
              id: session.id,
              title: session.title.isEmpty ? '未命名会话' : session.title,
              subtitle:
                  session.path ?? session.metadata?['description']?.toString(),
              createdAt: session.activeAt ?? session.updatedAt,
              lastModified: session.updatedAt,
              type: session.tag,
              messageCount: statsBySessionId[session.id]?.messageCount,
              changedLineCount: statsBySessionId[session.id]?.hasChanges == true
                  ? statsBySessionId[session.id]?.changedLineCount
                  : null,
            ),
          )
          .toList(),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        for (final group in groups)
          _SessionsGroupSection(
            header: _SessionSectionHeader(
              title: group.label,
              count: group.items.length,
              collapsed: _isDefaultGroupCollapsed(group.label),
              onTap: () => _toggleDefaultGroup(group.label),
            ),
            collapsed: _isDefaultGroupCollapsed(group.label),
            children: [
              for (final item in group.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SessionListItem(
                    session: sessionMap[item.id]!,
                    stats: statsBySessionId[item.id]!,
                    groupName: _groupNameForSession(item.id),
                    onTap: () => _openSession(sessionMap[item.id]!),
                    onDelete: () => _deleteSession(sessionMap[item.id]!),
                    onMove: () => _showMoveSessionSheet(sessionMap[item.id]!),
                    onLongPress: () =>
                        _showMoveSessionSheet(sessionMap[item.id]!),
                  ),
                ),
            ],
          ),
        if (unavailableSessions.isNotEmpty)
          _buildUnavailableSessionSection(
            sessions: unavailableSessions,
            statsBySessionId: statsBySessionId,
          ),
      ],
    );
  }

  Widget _buildUnavailableSessionSection({
    required List<Session> sessions,
    required Map<String, SessionStats> statsBySessionId,
  }) {
    final collapsed = _isDefaultGroupCollapsed(
      SessionsScreen.unavailableGroupLabel,
      defaultCollapsed: true,
    );
    return _SessionsGroupSection(
      header: _SessionSectionHeader(
        title: SessionsScreen.unavailableGroupLabel,
        count: sessions.length,
        collapsed: collapsed,
        subtle: true,
        onTap: () {
          _toggleDefaultGroup(
            SessionsScreen.unavailableGroupLabel,
            defaultCollapsed: true,
          );
        },
      ),
      collapsed: collapsed,
      children: [
        for (final session in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionListItem(
              session: session,
              stats: statsBySessionId[session.id]!,
              groupName: _groupNameForSession(session.id),
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
