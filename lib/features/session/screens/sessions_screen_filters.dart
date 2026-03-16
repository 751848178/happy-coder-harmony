part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  String? _sessionMachineId(Session session) {
    final machineId = session.metadata?['machineId']?.toString();
    if (machineId == null || machineId.trim().isEmpty) {
      return null;
    }
    return machineId.trim();
  }

  bool _matchesSelectedMachine(Session session, String? selectedMachineId) {
    if (selectedMachineId == null) {
      return true;
    }
    final machineId = _sessionMachineId(session);
    if (selectedMachineId == SessionsScreen.unknownMachineFilterId) {
      return machineId == null;
    }
    return machineId == selectedMachineId;
  }

  bool _matchesSessionFilters(
    Session session, {
    required String? selectedMachineId,
    required bool hideInactiveByDefault,
  }) {
    if (!_matchesSelectedMachine(session, selectedMachineId)) {
      return false;
    }
    if ((_showActiveOnly || hideInactiveByDefault) && !session.active) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    final query = _searchQuery.toLowerCase();
    return session.title.toLowerCase().contains(query) ||
        session.tag?.toLowerCase().contains(query) == true ||
        session.path?.toLowerCase().contains(query) == true;
  }

  bool _isSessionUnavailable(Session session) {
    return session.thinking != true && !session.active;
  }

  String? _groupNameForSession(String sessionId) {
    final groupId =
        _groupingService.groupIdForSession(_groupingState, sessionId);
    if (groupId == null) {
      return null;
    }
    for (final group in _groupingState.groups) {
      if (group.id == groupId) {
        return group.name;
      }
    }
    return null;
  }

  bool _isDefaultGroupCollapsed(
    String label, {
    bool defaultCollapsed = false,
  }) {
    if (defaultCollapsed) {
      return !_groupingState.expandedDefaultGroups.contains(label);
    }
    return _groupingState.collapsedDefaultGroups.contains(label);
  }

  Future<void> _toggleDefaultGroup(
    String label, {
    bool defaultCollapsed = false,
  }) {
    return _updateGroupingState(
      () => _groupingService.toggleDefaultGroupCollapsed(
        label,
        defaultCollapsed: defaultCollapsed,
      ),
    );
  }
}
