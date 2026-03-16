part of 'profile_models.dart';

/// AI backend profile configuration.
///
/// This matches Happy Coder's AIBackendProfile schema and is
/// synchronized between the app and CLI.
class AIProfile {
  final String id;
  final String name;
  final String? description;
  final AnthropicConfig? anthropicConfig;
  final OpenAIConfig? openaiConfig;
  final AzureOpenAIConfig? azureOpenAIConfig;
  final TogetherAIConfig? togetherAIConfig;
  final TmuxConfig? tmuxConfig;
  final List<EnvironmentVariable> environmentVariables;
  final SessionType? defaultSessionType;
  final PermissionMode? defaultPermissionMode;
  final String? defaultModelMode;
  final ProfileCompatibility compatibility;
  final bool isBuiltIn;
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

  Map<String, dynamic> toJson() => _aiProfileToJson(this);

  factory AIProfile.fromJson(Map<String, dynamic> json) =>
      _aiProfileFromJson(json);

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
      defaultPermissionMode:
          defaultPermissionMode ?? this.defaultPermissionMode,
      defaultModelMode: defaultModelMode ?? this.defaultModelMode,
      compatibility: compatibility ?? this.compatibility,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  String? get providerType {
    if (anthropicConfig != null) return 'anthropic';
    if (openaiConfig != null) return 'openai';
    if (azureOpenAIConfig != null) return 'azure';
    if (togetherAIConfig != null) return 'together';
    return null;
  }

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
