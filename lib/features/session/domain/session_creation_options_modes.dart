part of 'session_creation_options.dart';

List<SessionModeOption> permissionOptionsForAgent(
  String? agent, {
  dynamic metadataOptions,
}) {
  final mapped = _mapModeOptions(metadataOptions);
  if (mapped.isNotEmpty) {
    return mapped;
  }
  switch (normalizeSessionAgent(agent)) {
    case 'codex':
    case 'gemini':
      return const [
        SessionModeOption(key: 'default', label: '默认'),
        SessionModeOption(key: 'read-only', label: '只读'),
        SessionModeOption(key: 'safe-yolo', label: '安全自动'),
        SessionModeOption(key: 'yolo', label: '全自动'),
      ];
    case 'claude':
    default:
      return const [
        SessionModeOption(key: 'default', label: '默认'),
        SessionModeOption(key: 'acceptEdits', label: '自动改动'),
        SessionModeOption(key: 'plan', label: '规划'),
        SessionModeOption(key: 'bypassPermissions', label: '跳过权限'),
      ];
  }
}

List<SessionModeOption> newSessionPermissionOptionsForAgent(String? agent) {
  return permissionOptionsForAgent(agent);
}

List<SessionModeOption> modelOptionsForAgent(
  String? agent, {
  dynamic metadataOptions,
}) {
  final mapped = _mapModeOptions(metadataOptions);
  if (mapped.isNotEmpty) {
    return mapped;
  }
  return const [SessionModeOption(key: 'default', label: '默认')];
}

List<SessionModeOption> newSessionModelOptionsForAgent(String? agent) {
  return modelOptionsForAgent(agent);
}

String defaultPermissionModeForAgent(String? agent) {
  return permissionOptionsForAgent(agent).first.key;
}

String defaultModelModeForAgent(String? agent) {
  return modelOptionsForAgent(agent).first.key;
}

List<SessionModeOption> _mapModeOptions(dynamic metadataOptions) {
  if (metadataOptions is! List) {
    return const [];
  }
  return metadataOptions
      .map((item) => item is Map ? SessionModeOption.fromMap(item) : null)
      .whereType<SessionModeOption>()
      .toList();
}
