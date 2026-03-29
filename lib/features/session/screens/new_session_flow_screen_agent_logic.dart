part of 'new_session_flow_screen.dart';

void _selectSessionFlowAgent(_NewSessionFlowScreenState state, String agent) {
  final normalized = normalizeSessionAgent(agent);
  if (state._selectedAgent == normalized) {
    return;
  }

  final notifier = state.ref.read(sessionStateProvider.notifier);
  final permissionOptions = _sessionFlowPermissionOptions(
    state,
    agent: normalized,
  );
  final modelOptions = _sessionFlowModelOptions(
    state,
    agent: normalized,
  );
  final currentPermission = permissionOptions
      .where((option) => option.key == state._permissionMode)
      .cast<SessionModeOption?>()
      .firstWhere((option) => option != null, orElse: () => null);
  final currentModel = modelOptions
      .where((option) => option.key == state._modelMode)
      .cast<SessionModeOption?>()
      .firstWhere((option) => option != null, orElse: () => null);

  state._updateView(() {
    state._selectedAgent = normalized;
    _syncSessionFlowModeSelections(
      state,
      agent: normalized,
      preferredPermissionMode: currentPermission?.key,
      preferredModelMode: currentModel?.key,
    );
  });
}

void _cycleSessionFlowAgent(_NewSessionFlowScreenState state) {
  final currentIndex = supportedSessionAgents.indexOf(state._selectedAgent);
  final nextIndex =
      currentIndex < 0 ? 0 : (currentIndex + 1) % supportedSessionAgents.length;
  _selectSessionFlowAgent(state, supportedSessionAgents[nextIndex]);
}

String _compactSessionFlowPath(String path) {
  final normalized = path.trim();
  if (normalized.length <= 36) {
    return normalized;
  }
  return '...${normalized.substring(normalized.length - 33)}';
}

Color _sessionFlowModeTint(String agent, String modeKey) {
  if (agent == 'codex') {
    switch (modeKey) {
      case 'read-only':
        return AppTheme.infoColor;
      case 'safe-yolo':
        return AppTheme.successColor;
      case 'yolo':
        return AppTheme.warningColor;
    }
  }
  switch (modeKey) {
    case 'acceptEdits':
      return AppTheme.successColor;
    case 'plan':
      return AppTheme.infoColor;
    case 'bypassPermissions':
      return AppTheme.warningColor;
    default:
      return AppTheme.neutral600;
  }
}
