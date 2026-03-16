part of 'new_session_flow_screen.dart';

void _selectSessionFlowAgent(_NewSessionFlowScreenState state, String agent) {
  final normalized = normalizeSessionAgent(agent);
  if (state._selectedAgent == normalized) {
    return;
  }

  final profileState = state.ref.read(profileStateProvider);
  final profiles = profileState is ProfileLoaded
      ? profileState.profiles
      : profile_models.BuiltInProfiles.all();
  final currentProfile =
      _findSessionFlowProfileById(profiles, state._selectedProfileId);
  final nextProfile =
      currentProfile != null && currentProfile.isCompatibleWith(normalized)
          ? currentProfile
          : null;

  state._updateView(() {
    state._selectedAgent = normalized;
    state._selectedProfileId = nextProfile?.id;
    state._permissionMode = resolveModeSelection(
      preferred:
          nextProfile?.defaultPermissionMode?.value ?? state._permissionMode,
      options: permissionOptionsForAgent(normalized),
      fallback: defaultPermissionModeForAgent(normalized),
    );
    state._modelMode = resolveModeSelection(
      preferred: nextProfile?.defaultModelMode ?? state._modelMode,
      options: modelOptionsForAgent(normalized),
      fallback: defaultModelModeForAgent(normalized),
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
