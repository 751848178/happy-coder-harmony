part of 'new_session_flow_screen.dart';

String _effectiveSessionFlowDirectory(
  _NewSessionFlowScreenState state,
  _MachineOption? machine,
) {
  final manual = state._pathController.text.trim();
  if (manual.isNotEmpty) {
    return manual;
  }
  return machine?.homeDir?.trim() ?? '';
}

String? _defaultSessionFlowPathForMachine(
  String machineId,
  List<Session> sessions,
  List<_MachineOption> machines,
) {
  return _mostRecentSessionFlowPathForMachine(machineId, sessions) ??
      machines
          .where((item) => item.id == machineId)
          .cast<_MachineOption?>()
          .firstWhere((item) => item != null, orElse: () => null)
          ?.homeDir;
}

String? _mostRecentSessionFlowPathForMachine(
  String machineId,
  List<Session> sessions,
) {
  final items = sessions
      .where(
          (session) => session.metadata?['machineId']?.toString() == machineId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final session in items) {
    final path = session.path ?? session.metadata?['path']?.toString() ?? '';
    if (path.isNotEmpty) {
      return path;
    }
  }
  return null;
}

profile_models.AIProfile? _resolveSessionFlowProfile({
  required List<profile_models.AIProfile> profiles,
  required String? preferredId,
}) {
  return _findSessionFlowProfileById(profiles, preferredId);
}

profile_models.AIProfile? _findSessionFlowProfileById(
  List<profile_models.AIProfile> profiles,
  String? profileId,
) {
  if (profileId == null || profileId.isEmpty) {
    return null;
  }
  return profiles
      .where((profile) => profile.id == profileId)
      .cast<profile_models.AIProfile?>()
      .firstWhere((profile) => profile != null, orElse: () => null);
}
