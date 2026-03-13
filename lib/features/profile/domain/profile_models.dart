/// Profile models matching Happy Coder's AIBackendProfile schema
///
/// These models are synchronized between the app and CLI for
/// consistent AI backend configuration.

/// Anthropic AI provider configuration
class AnthropicConfig {
  final String? baseUrl;
  final String? authToken;
  final String? model;

  const AnthropicConfig({
    this.baseUrl,
    this.authToken,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'authToken': authToken,
      'model': model,
    };
  }

  factory AnthropicConfig.fromJson(Map<String, dynamic> json) {
    return AnthropicConfig(
      baseUrl: json['baseUrl'] as String?,
      authToken: json['authToken'] as String?,
      model: json['model'] as String?,
    );
  }

  AnthropicConfig copyWith({
    String? baseUrl,
    String? authToken,
    String? model,
  }) {
    return AnthropicConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      authToken: authToken ?? this.authToken,
      model: model ?? this.model,
    );
  }
}

/// OpenAI provider configuration
class OpenAIConfig {
  final String? apiKey;
  final String? baseUrl;
  final String? model;

  const OpenAIConfig({
    this.apiKey,
    this.baseUrl,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
    };
  }

  factory OpenAIConfig.fromJson(Map<String, dynamic> json) {
    return OpenAIConfig(
      apiKey: json['apiKey'] as String?,
      baseUrl: json['baseUrl'] as String?,
      model: json['model'] as String?,
    );
  }

  OpenAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    return OpenAIConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }
}

/// Azure OpenAI provider configuration
class AzureOpenAIConfig {
  final String? apiKey;
  final String? endpoint;
  final String? apiVersion;
  final String? deploymentName;

  const AzureOpenAIConfig({
    this.apiKey,
    this.endpoint,
    this.apiVersion,
    this.deploymentName,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'endpoint': endpoint,
      'apiVersion': apiVersion,
      'deploymentName': deploymentName,
    };
  }

  factory AzureOpenAIConfig.fromJson(Map<String, dynamic> json) {
    return AzureOpenAIConfig(
      apiKey: json['apiKey'] as String?,
      endpoint: json['endpoint'] as String?,
      apiVersion: json['apiVersion'] as String?,
      deploymentName: json['deploymentName'] as String?,
    );
  }

  AzureOpenAIConfig copyWith({
    String? apiKey,
    String? endpoint,
    String? apiVersion,
    String? deploymentName,
  }) {
    return AzureOpenAIConfig(
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      apiVersion: apiVersion ?? this.apiVersion,
      deploymentName: deploymentName ?? this.deploymentName,
    );
  }
}

/// Together AI provider configuration
class TogetherAIConfig {
  final String? apiKey;
  final String? model;

  const TogetherAIConfig({
    this.apiKey,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'model': model,
    };
  }

  factory TogetherAIConfig.fromJson(Map<String, dynamic> json) {
    return TogetherAIConfig(
      apiKey: json['apiKey'] as String?,
      model: json['model'] as String?,
    );
  }

  TogetherAIConfig copyWith({
    String? apiKey,
    String? model,
  }) {
    return TogetherAIConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

/// Tmux configuration for session management
class TmuxConfig {
  final String? sessionName;
  final String? tmpDir;
  final bool? updateEnvironment;

  const TmuxConfig({
    this.sessionName,
    this.tmpDir,
    this.updateEnvironment,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionName': sessionName,
      'tmpDir': tmpDir,
      'updateEnvironment': updateEnvironment,
    };
  }

  factory TmuxConfig.fromJson(Map<String, dynamic> json) {
    return TmuxConfig(
      sessionName: json['sessionName'] as String?,
      tmpDir: json['tmpDir'] as String?,
      updateEnvironment: json['updateEnvironment'] as bool?,
    );
  }

  TmuxConfig copyWith({
    String? sessionName,
    String? tmpDir,
    bool? updateEnvironment,
  }) {
    return TmuxConfig(
      sessionName: sessionName ?? this.sessionName,
      tmpDir: tmpDir ?? this.tmpDir,
      updateEnvironment: updateEnvironment ?? this.updateEnvironment,
    );
  }
}

/// Environment variable with name and value
class EnvironmentVariable {
  final String name;
  final String value;

  const EnvironmentVariable({
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) {
    return EnvironmentVariable(
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  EnvironmentVariable copyWith({
    String? name,
    String? value,
  }) {
    return EnvironmentVariable(
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

/// Profile compatibility settings for different agents
class ProfileCompatibility {
  final bool claude;
  final bool codex;
  final bool gemini;

  const ProfileCompatibility({
    this.claude = true,
    this.codex = true,
    this.gemini = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'claude': claude,
      'codex': codex,
      'gemini': gemini,
    };
  }

  factory ProfileCompatibility.fromJson(Map<String, dynamic> json) {
    return ProfileCompatibility(
      claude: json['claude'] as bool? ?? true,
      codex: json['codex'] as bool? ?? true,
      gemini: json['gemini'] as bool? ?? true,
    );
  }

  ProfileCompatibility copyWith({
    bool? claude,
    bool? codex,
    bool? gemini,
  }) {
    return ProfileCompatibility(
      claude: claude ?? this.claude,
      codex: codex ?? this.codex,
      gemini: gemini ?? this.gemini,
    );
  }
}

/// Default permission mode for profile
enum PermissionMode {
  // Claude modes
  defaultMode,
  acceptEdits,
  bypassPermissions,
  plan,
  // Codex modes
  readOnly,
  safeYolo,
  yolo;

  String get displayName {
    switch (this) {
      case PermissionMode.defaultMode:
        return '默认';
      case PermissionMode.acceptEdits:
        return '接受编辑';
      case PermissionMode.bypassPermissions:
        return '绕过权限';
      case PermissionMode.plan:
        return '计划模式';
      case PermissionMode.readOnly:
        return '只读';
      case PermissionMode.safeYolo:
        return '安全快速';
      case PermissionMode.yolo:
        return '完全自动';
    }
  }

  String get value {
    switch (this) {
      case PermissionMode.defaultMode:
        return 'default';
      case PermissionMode.acceptEdits:
        return 'acceptEdits';
      case PermissionMode.bypassPermissions:
        return 'bypassPermissions';
      case PermissionMode.plan:
        return 'plan';
      case PermissionMode.readOnly:
        return 'read-only';
      case PermissionMode.safeYolo:
        return 'safe-yolo';
      case PermissionMode.yolo:
        return 'yolo';
    }
  }

  static PermissionMode fromString(String value) {
    switch (value) {
      case 'default':
        return PermissionMode.defaultMode;
      case 'acceptEdits':
        return PermissionMode.acceptEdits;
      case 'bypassPermissions':
        return PermissionMode.bypassPermissions;
      case 'plan':
        return PermissionMode.plan;
      case 'read-only':
        return PermissionMode.readOnly;
      case 'safe-yolo':
        return PermissionMode.safeYolo;
      case 'yolo':
        return PermissionMode.yolo;
      default:
        return PermissionMode.defaultMode;
    }
  }
}

/// Default session type for profile
enum SessionType {
  simple,
  worktree;

  String get displayName {
    switch (this) {
      case SessionType.simple:
        return '简单会话';
      case SessionType.worktree:
        return '工作树';
    }
  }

  String get value {
    switch (this) {
      case SessionType.simple:
        return 'simple';
      case SessionType.worktree:
        return 'worktree';
    }
  }

  static SessionType fromString(String value) {
    switch (value) {
      case 'simple':
        return SessionType.simple;
      case 'worktree':
        return SessionType.worktree;
      default:
        return SessionType.simple;
    }
  }
}

/// AI backend profile configuration
///
/// This matches Happy Coder's AIBackendProfile schema and is
/// synchronized between the app and CLI.
class AIProfile {
  final String id;
  final String name;
  final String? description;

  // Agent-specific configurations
  final AnthropicConfig? anthropicConfig;
  final OpenAIConfig? openaiConfig;
  final AzureOpenAIConfig? azureOpenAIConfig;
  final TogetherAIConfig? togetherAIConfig;

  // Tmux configuration
  final TmuxConfig? tmuxConfig;

  // Environment variables
  final List<EnvironmentVariable> environmentVariables;

  // Default settings for this profile
  final SessionType? defaultSessionType;
  final PermissionMode? defaultPermissionMode;
  final String? defaultModelMode;

  // Compatibility metadata
  final ProfileCompatibility compatibility;

  // Built-in profile indicator
  final bool isBuiltIn;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;

  AIProfile({
    required this.id,
    required this.name,
    this.description,
    this.anthropicConfig,
    this.openaiConfig,
    this.azureOpenAIConfig,
    this.togetherAIConfig,
    this.tmuxConfig,
    this.environmentVariables = const [],
    this.defaultSessionType,
    this.defaultPermissionMode,
    this.defaultModelMode,
    this.compatibility = const ProfileCompatibility(),
    this.isBuiltIn = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.version = '1.0.0',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'anthropicConfig': anthropicConfig?.toJson(),
      'openaiConfig': openaiConfig?.toJson(),
      'azureOpenAIConfig': azureOpenAIConfig?.toJson(),
      'togetherAIConfig': togetherAIConfig?.toJson(),
      'tmuxConfig': tmuxConfig?.toJson(),
      'environmentVariables':
          environmentVariables.map((e) => e.toJson()).toList(),
      'defaultSessionType': defaultSessionType?.value,
      'defaultPermissionMode': defaultPermissionMode?.value,
      'defaultModelMode': defaultModelMode,
      'compatibility': compatibility.toJson(),
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'version': version,
    };
  }

  factory AIProfile.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as int?;
    final updatedAt = json['updatedAt'] as int?;

    return AIProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      anthropicConfig: json['anthropicConfig'] != null
          ? AnthropicConfig.fromJson(
              json['anthropicConfig'] as Map<String, dynamic>)
          : null,
      openaiConfig: json['openaiConfig'] != null
          ? OpenAIConfig.fromJson(json['openaiConfig'] as Map<String, dynamic>)
          : null,
      azureOpenAIConfig: json['azureOpenAIConfig'] != null
          ? AzureOpenAIConfig.fromJson(
              json['azureOpenAIConfig'] as Map<String, dynamic>)
          : null,
      togetherAIConfig: json['togetherAIConfig'] != null
          ? TogetherAIConfig.fromJson(
              json['togetherAIConfig'] as Map<String, dynamic>)
          : null,
      tmuxConfig: json['tmuxConfig'] != null
          ? TmuxConfig.fromJson(json['tmuxConfig'] as Map<String, dynamic>)
          : null,
      environmentVariables: (json['environmentVariables'] as List?)
              ?.map((e) => EnvironmentVariable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultSessionType: json['defaultSessionType'] != null
          ? SessionType.fromString(json['defaultSessionType'] as String)
          : null,
      defaultPermissionMode: json['defaultPermissionMode'] != null
          ? PermissionMode.fromString(json['defaultPermissionMode'] as String)
          : null,
      defaultModelMode: json['defaultModelMode'] as String?,
      compatibility: json['compatibility'] != null
          ? ProfileCompatibility.fromJson(
              json['compatibility'] as Map<String, dynamic>)
          : const ProfileCompatibility(),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt) : null,
      updatedAt: updatedAt != null ? DateTime.fromMillisecondsSinceEpoch(updatedAt) : null,
      version: json['version'] as String? ?? '1.0.0',
    );
  }

  AIProfile copyWith({
    String? id,
    String? name,
    String? description,
    AnthropicConfig? anthropicConfig,
    OpenAIConfig? openaiConfig,
    AzureOpenAIConfig? azureOpenAIConfig,
    TogetherAIConfig? togetherAIConfig,
    TmuxConfig? tmuxConfig,
    List<EnvironmentVariable>? environmentVariables,
    SessionType? defaultSessionType,
    PermissionMode? defaultPermissionMode,
    String? defaultModelMode,
    ProfileCompatibility? compatibility,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version,
  }) {
    return AIProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      anthropicConfig: anthropicConfig ?? this.anthropicConfig,
      openaiConfig: openaiConfig ?? this.openaiConfig,
      azureOpenAIConfig: azureOpenAIConfig ?? this.azureOpenAIConfig,
      togetherAIConfig: togetherAIConfig ?? this.togetherAIConfig,
      tmuxConfig: tmuxConfig ?? this.tmuxConfig,
      environmentVariables: environmentVariables ?? this.environmentVariables,
      defaultSessionType: defaultSessionType ?? this.defaultSessionType,
      defaultPermissionMode: defaultPermissionMode ?? this.defaultPermissionMode,
      defaultModelMode: defaultModelMode ?? this.defaultModelMode,
      compatibility: compatibility ?? this.compatibility,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  /// Get the primary AI provider type for this profile
  String? get providerType {
    if (anthropicConfig != null) return 'anthropic';
    if (openaiConfig != null) return 'openai';
    if (azureOpenAIConfig != null) return 'azure';
    if (togetherAIConfig != null) return 'together';
    return null;
  }

  /// Get display name for the provider
  String? get providerDisplayName {
    switch (providerType) {
      case 'anthropic':
        return 'Anthropic (Claude)';
      case 'openai':
        return 'OpenAI (GPT)';
      case 'azure':
        return 'Azure OpenAI';
      case 'together':
        return 'Together AI';
      default:
        return null;
    }
  }

  /// Check if profile is compatible with a specific agent
  bool isCompatibleWith(String agent) {
    switch (agent) {
      case 'claude':
        return compatibility.claude;
      case 'codex':
        return compatibility.codex;
      case 'gemini':
        return compatibility.gemini;
      default:
        return false;
    }
  }
}

/// Built-in profile templates
class BuiltInProfiles {
  // Claude 3.5 Sonnet - Best for general coding
  static final claude35Sonnet = AIProfile(
    id: 'claude-35-sonnet',
    name: 'Claude 3.5 Sonnet',
    description: '最适合通用编程任务的 Claude 模型',
    anthropicConfig: const AnthropicConfig(model: 'claude-3-5-sonnet'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: true,
      codex: false,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // Claude 3.5 Haiku - Fast and cost-effective
  static final claude35Haiku = AIProfile(
    id: 'claude-35-haiku',
    name: 'Claude 3.5 Haiku',
    description: '快速且经济的 Claude 模型，适合简单任务',
    anthropicConfig: const AnthropicConfig(model: 'claude-3-5-haiku'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: true,
      codex: false,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // Claude 3.5 Opus - Most capable
  static final claude35Opus = AIProfile(
    id: 'claude-35-opus',
    name: 'Claude 3.5 Opus',
    description: '最强大的 Claude 模型，适合复杂任务',
    anthropicConfig: const AnthropicConfig(model: 'claude-3-5-opus'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: true,
      codex: false,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // GPT-4o - OpenAI's latest
  static final gpt4o = AIProfile(
    id: 'gpt-4o',
    name: 'GPT-4o',
    description: 'OpenAI 最先进的 GPT 模型',
    openaiConfig: const OpenAIConfig(model: 'gpt-4o'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: false,
      codex: true,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // GPT-4 Turbo - Fast and cost-effective
  static final gpt4Turbo = AIProfile(
    id: 'gpt-4-turbo',
    name: 'GPT-4 Turbo',
    description: '快速且经济的 GPT 模型',
    openaiConfig: const OpenAIConfig(model: 'gpt-4-turbo'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: false,
      codex: true,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // o1-preview - OpenAI reasoning model
  static final o1Preview = AIProfile(
    id: 'o1-preview',
    name: 'o1-preview',
    description: 'OpenAI 推理模型，适合数学和逻辑任务',
    openaiConfig: const OpenAIConfig(model: 'o1-preview'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: false,
      codex: true,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // Azure GPT-4o
  static final azureGpt4o = AIProfile(
    id: 'azure-gpt-4o',
    name: 'Azure GPT-4o',
    description: 'Azure 托管的 GPT-4o 模型',
    azureOpenAIConfig: const AzureOpenAIConfig(),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: false,
      codex: true,
      gemini: false,
    ),
    isBuiltIn: true,
  );

  // Mixtral 8x7B - Open source
  static final mixtral8x7b = AIProfile(
    id: 'mixtral-8x7b',
    name: 'Mixtral 8x7B',
    description: '开源的高性能模型',
    togetherAIConfig: const TogetherAIConfig(
      model: 'mistral-8x7b-instruct-v0.1',
    ),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: true,
      codex: true,
      gemini: true,
    ),
    isBuiltIn: true,
  );

  // Llama 3.1 70B - Meta's model
  static final llama370b = AIProfile(
    id: 'llama-3-1-70b',
    name: 'Llama 3.1 70B',
    description: 'Meta 的开源大语言模型',
    togetherAIConfig: const TogetherAIConfig(
      model: 'llama-3-1b',
    ),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(
      claude: true,
      codex: true,
      gemini: true,
    ),
    isBuiltIn: true,
  );

  // Legacy default for compatibility
  static final claudeDefault = claude35Sonnet;
  static final openaiDefault = gpt4o;

  /// Get all built-in profiles
  static List<AIProfile> all() => [
    claude35Sonnet,
    claude35Haiku,
    claude35Opus,
    gpt4o,
    gpt4Turbo,
    o1Preview,
    azureGpt4o,
    mixtral8x7b,
    llama370b,
  ];

  /// Get recommended profile for new users
  static AIProfile get recommended => claude35Sonnet;

  /// Get profile by ID
  static AIProfile? byId(String id) {
    try {
      return all().firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get profiles by provider type
  static List<AIProfile> getByProvider(String provider) {
    switch (provider) {
      case 'anthropic':
        return [claude35Sonnet, claude35Haiku, claude35Opus];
      case 'openai':
        return [gpt4o, gpt4Turbo, o1Preview];
      case 'azure':
        return [azureGpt4o];
      case 'together':
        return [mixtral8x7b, llama370b];
      default:
        return [];
    }
  }
}
