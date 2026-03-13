import '../../profile/domain/profile_models.dart' as profile_models;

class SessionModeOption {
  const SessionModeOption({
    required this.key,
    required this.label,
    this.description,
  });

  final String key;
  final String label;
  final String? description;

  factory SessionModeOption.fromMap(Map<dynamic, dynamic> map) {
    return SessionModeOption(
      key: map['code']?.toString() ?? map['key']?.toString() ?? 'default',
      label: map['value']?.toString() ?? map['name']?.toString() ?? '默认',
      description: map['description']?.toString(),
    );
  }
}

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

List<SessionModeOption> permissionOptionsForAgent(
  String? agent, {
  dynamic metadataOptions,
}) {
  if (metadataOptions is List) {
    final mapped = metadataOptions
        .map((item) => item is Map ? SessionModeOption.fromMap(item) : null)
        .whereType<SessionModeOption>()
        .toList();
    if (mapped.isNotEmpty) {
      return mapped;
    }
  }

  switch (normalizeSessionAgent(agent)) {
    case 'codex':
    case 'gemini':
      return const <SessionModeOption>[
        SessionModeOption(key: 'default', label: '默认'),
        SessionModeOption(key: 'read-only', label: '只读'),
        SessionModeOption(key: 'safe-yolo', label: '安全自动'),
        SessionModeOption(key: 'yolo', label: '全自动'),
      ];
    case 'claude':
    default:
      return const <SessionModeOption>[
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
  if (metadataOptions is List) {
    final mapped = metadataOptions
        .map((item) => item is Map ? SessionModeOption.fromMap(item) : null)
        .whereType<SessionModeOption>()
        .toList();
    if (mapped.isNotEmpty) {
      return mapped;
    }
  }

  switch (normalizeSessionAgent(agent)) {
    case 'codex':
      return const <SessionModeOption>[
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
      return const <SessionModeOption>[
        SessionModeOption(key: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro'),
        SessionModeOption(key: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash'),
        SessionModeOption(
            key: 'gemini-2.5-flash-lite', label: 'Gemini 2.5 Flash Lite'),
      ];
    case 'claude':
    default:
      return const <SessionModeOption>[
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

Map<String, String> buildProfileEnvironmentVariables(
  profile_models.AIProfile profile,
) {
  final envVars = <String, String>{};

  for (final item in profile.environmentVariables) {
    envVars[item.name] = item.value;
  }

  final anthropic = profile.anthropicConfig;
  if (anthropic != null) {
    if ((anthropic.baseUrl ?? '').isNotEmpty) {
      envVars['ANTHROPIC_BASE_URL'] = anthropic.baseUrl!;
    }
    if ((anthropic.authToken ?? '').isNotEmpty) {
      envVars['ANTHROPIC_AUTH_TOKEN'] = anthropic.authToken!;
    }
    if ((anthropic.model ?? '').isNotEmpty) {
      envVars['ANTHROPIC_MODEL'] = anthropic.model!;
    }
  }

  final openai = profile.openaiConfig;
  if (openai != null) {
    if ((openai.apiKey ?? '').isNotEmpty) {
      envVars['OPENAI_API_KEY'] = openai.apiKey!;
    }
    if ((openai.baseUrl ?? '').isNotEmpty) {
      envVars['OPENAI_BASE_URL'] = openai.baseUrl!;
    }
    if ((openai.model ?? '').isNotEmpty) {
      envVars['OPENAI_MODEL'] = openai.model!;
    }
  }

  final azure = profile.azureOpenAIConfig;
  if (azure != null) {
    if ((azure.apiKey ?? '').isNotEmpty) {
      envVars['AZURE_OPENAI_API_KEY'] = azure.apiKey!;
    }
    if ((azure.endpoint ?? '').isNotEmpty) {
      envVars['AZURE_OPENAI_ENDPOINT'] = azure.endpoint!;
    }
    if ((azure.apiVersion ?? '').isNotEmpty) {
      envVars['AZURE_OPENAI_API_VERSION'] = azure.apiVersion!;
    }
    if ((azure.deploymentName ?? '').isNotEmpty) {
      envVars['AZURE_OPENAI_DEPLOYMENT_NAME'] = azure.deploymentName!;
    }
  }

  final together = profile.togetherAIConfig;
  if (together != null) {
    if ((together.apiKey ?? '').isNotEmpty) {
      envVars['TOGETHER_API_KEY'] = together.apiKey!;
    }
    if ((together.model ?? '').isNotEmpty) {
      envVars['TOGETHER_MODEL'] = together.model!;
    }
  }

  final tmux = profile.tmuxConfig;
  if (tmux != null) {
    if (tmux.sessionName != null) {
      envVars['TMUX_SESSION_NAME'] = tmux.sessionName!;
    }
    if (tmux.tmpDir != null) {
      envVars['TMUX_TMPDIR'] = tmux.tmpDir!;
    }
    if (tmux.updateEnvironment != null) {
      envVars['TMUX_UPDATE_ENVIRONMENT'] = tmux.updateEnvironment!.toString();
    }
  }

  return envVars;
}
