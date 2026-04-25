part of 'session_creation_options.dart';

const List<String> supportedSessionAgents = <String>[
  'claude',
  'codex',
];

String normalizeSessionAgent(String? value) {
  switch (value) {
    case 'codex':
      return 'codex';
    case 'gemini':
      return 'gemini';
    case 'claude':
    default:
      return 'claude';
  }
}

String sessionAgentLabel(String? agent) {
  switch (normalizeSessionAgent(agent)) {
    case 'codex':
      return 'Codex';
    case 'gemini':
      return 'Gemini';
    case 'claude':
    default:
      return 'Claude Code';
  }
}

String resolvePreferredAgentForProfile(
  profile_models.AIProfile profile, {
  String? fallback,
}) {
  final normalizedFallback = normalizeSessionAgent(fallback);
  if (profile.isCompatibleWith(normalizedFallback)) {
    return normalizedFallback;
  }
  if (profile.compatibility.claude && !profile.compatibility.codex) {
    return 'claude';
  }
  if (profile.compatibility.codex && !profile.compatibility.claude) {
    return 'codex';
  }
  switch (profile.providerType) {
    case 'openai':
    case 'azure':
      return 'codex';
    default:
      return 'claude';
  }
}
