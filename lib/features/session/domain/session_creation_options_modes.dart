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

List<SessionModeOption> modelOptionsForAgent(
  String? agent, {
  dynamic metadataOptions,
}) {
  final mapped = _mapModeOptions(metadataOptions);
  if (mapped.isNotEmpty) {
    return mapped;
  }
  switch (normalizeSessionAgent(agent)) {
    case 'codex':
      return const [
        SessionModeOption(key: 'gpt-5-codex-high', label: 'GPT-5 Codex High'),
        SessionModeOption(
            key: 'gpt-5-codex-medium', label: 'GPT-5 Codex Medium'),
        SessionModeOption(key: 'gpt-5-codex-low', label: 'GPT-5 Codex Low'),
        SessionModeOption(key: 'gpt-5-minimal', label: 'GPT-5 Minimal'),
        SessionModeOption(key: 'gpt-5-low', label: 'GPT-5 Low'),
        SessionModeOption(key: 'gpt-5-medium', label: 'GPT-5 Medium'),
        SessionModeOption(key: 'gpt-5-high', label: 'GPT-5 High'),
      ];
    case 'gemini':
      return const [
        SessionModeOption(key: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro'),
        SessionModeOption(key: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash'),
        SessionModeOption(
            key: 'gemini-2.5-flash-lite', label: 'Gemini 2.5 Flash Lite'),
      ];
    case 'claude':
    default:
      return const [
        SessionModeOption(key: 'default', label: 'Default'),
        SessionModeOption(key: 'adaptiveUsage', label: 'Adaptive Usage'),
        SessionModeOption(key: 'sonnet', label: 'Sonnet'),
        SessionModeOption(key: 'opus', label: 'Opus'),
      ];
  }
}

String defaultPermissionModeForAgent(String? agent) {
  return permissionOptionsForAgent(agent).first.key;
}

String defaultModelModeForAgent(String? agent) {
  return modelOptionsForAgent(agent).first.key;
}

String resolveModeSelection({
  required String? preferred,
  required List<SessionModeOption> options,
  required String fallback,
}) {
  if (preferred != null && preferred.isNotEmpty) {
    for (final option in options) {
      if (option.key == preferred) {
        return option.key;
      }
    }
  }
  return fallback;
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
