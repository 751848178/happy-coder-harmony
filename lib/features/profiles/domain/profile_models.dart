import '../../profile/domain/profile_models.dart' as core;

typedef AIBackendProfile = core.AIProfile;
typedef AnthropicConfig = core.AnthropicConfig;
typedef OpenAIConfig = core.OpenAIConfig;
typedef AzureOpenAIConfig = core.AzureOpenAIConfig;
typedef TogetherAIConfig = core.TogetherAIConfig;
typedef TmuxConfig = core.TmuxConfig;
typedef EnvironmentVariable = core.EnvironmentVariable;
typedef ProfileCompatibility = core.ProfileCompatibility;
typedef SessionType = core.SessionType;
typedef PermissionMode = core.PermissionMode;

/// Thin request DTO kept for compatibility with the legacy `features/profiles`
/// surface while reusing the canonical profile domain models.
class ProfileRequest {
  const ProfileRequest({
    this.id,
    required this.name,
    this.description,
    this.anthropicConfig,
    this.openaiConfig,
    this.azureOpenAIConfig,
    this.tmuxConfig,
    this.togetherAIConfig,
    this.environmentVariables,
    this.defaultSessionType,
    this.defaultPermissionMode,
    this.defaultModelMode,
    this.compatibility,
  });

  final String? id;
  final String name;
  final String? description;
  final AnthropicConfig? anthropicConfig;
  final OpenAIConfig? openaiConfig;
  final AzureOpenAIConfig? azureOpenAIConfig;
  final TmuxConfig? tmuxConfig;
  final TogetherAIConfig? togetherAIConfig;
  final List<EnvironmentVariable>? environmentVariables;
  final SessionType? defaultSessionType;
  final PermissionMode? defaultPermissionMode;
  final String? defaultModelMode;
  final ProfileCompatibility? compatibility;

  factory ProfileRequest.fromProfile(AIBackendProfile profile) {
    return ProfileRequest(
      id: profile.id,
      name: profile.name,
      description: profile.description,
      anthropicConfig: profile.anthropicConfig,
      openaiConfig: profile.openaiConfig,
      azureOpenAIConfig: profile.azureOpenAIConfig,
      tmuxConfig: profile.tmuxConfig,
      togetherAIConfig: profile.togetherAIConfig,
      environmentVariables: profile.environmentVariables,
      defaultSessionType: profile.defaultSessionType,
      defaultPermissionMode: profile.defaultPermissionMode,
      defaultModelMode: profile.defaultModelMode,
      compatibility: profile.compatibility,
    );
  }

  ProfileRequest copyWith({
    String? id,
    String? name,
    String? description,
    AnthropicConfig? anthropicConfig,
    OpenAIConfig? openaiConfig,
    AzureOpenAIConfig? azureOpenAIConfig,
    TmuxConfig? tmuxConfig,
    TogetherAIConfig? togetherAIConfig,
    List<EnvironmentVariable>? environmentVariables,
    SessionType? defaultSessionType,
    PermissionMode? defaultPermissionMode,
    String? defaultModelMode,
    ProfileCompatibility? compatibility,
  }) {
    return ProfileRequest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      anthropicConfig: anthropicConfig ?? this.anthropicConfig,
      openaiConfig: openaiConfig ?? this.openaiConfig,
      azureOpenAIConfig: azureOpenAIConfig ?? this.azureOpenAIConfig,
      tmuxConfig: tmuxConfig ?? this.tmuxConfig,
      togetherAIConfig: togetherAIConfig ?? this.togetherAIConfig,
      environmentVariables: environmentVariables ?? this.environmentVariables,
      defaultSessionType: defaultSessionType ?? this.defaultSessionType,
      defaultPermissionMode:
          defaultPermissionMode ?? this.defaultPermissionMode,
      defaultModelMode: defaultModelMode ?? this.defaultModelMode,
      compatibility: compatibility ?? this.compatibility,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (anthropicConfig != null) 'anthropicConfig': anthropicConfig!.toJson(),
      if (openaiConfig != null) 'openaiConfig': openaiConfig!.toJson(),
      if (azureOpenAIConfig != null)
        'azureOpenAIConfig': azureOpenAIConfig!.toJson(),
      if (tmuxConfig != null) 'tmuxConfig': tmuxConfig!.toJson(),
      if (togetherAIConfig != null)
        'togetherAIConfig': togetherAIConfig!.toJson(),
      if (environmentVariables != null)
        'environmentVariables':
            environmentVariables!.map((item) => item.toJson()).toList(),
      if (defaultSessionType != null)
        'defaultSessionType': defaultSessionType!.value,
      if (defaultPermissionMode != null)
        'defaultPermissionMode': defaultPermissionMode!.value,
      if (defaultModelMode != null) 'defaultModelMode': defaultModelMode,
      if (compatibility != null) 'compatibility': compatibility!.toJson(),
    };
  }

  AIBackendProfile toProfile({
    String? profileId,
    bool isBuiltIn = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String version = '1.0.0',
  }) {
    final resolvedId = profileId ?? id;
    if (resolvedId == null || resolvedId.isEmpty) {
      throw ArgumentError('profileId is required');
    }

    return AIBackendProfile(
      id: resolvedId,
      name: name,
      description: description,
      anthropicConfig: anthropicConfig,
      openaiConfig: openaiConfig,
      azureOpenAIConfig: azureOpenAIConfig,
      tmuxConfig: tmuxConfig,
      togetherAIConfig: togetherAIConfig,
      environmentVariables: environmentVariables ?? const [],
      defaultSessionType: defaultSessionType,
      defaultPermissionMode: defaultPermissionMode,
      defaultModelMode: defaultModelMode,
      compatibility: compatibility ?? const ProfileCompatibility(),
      isBuiltIn: isBuiltIn,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
    );
  }
}

class ProfileListResponse {
  const ProfileListResponse({required this.items});

  final List<AIBackendProfile> items;

  factory ProfileListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ProfileListResponse(
      items: rawItems
          .map(
              (item) => AIBackendProfile.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
