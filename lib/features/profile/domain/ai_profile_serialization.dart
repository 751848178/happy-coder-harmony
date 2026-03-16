part of 'profile_models.dart';

Map<String, dynamic> _aiProfileToJson(AIProfile profile) {
  return {
    'id': profile.id,
    'name': profile.name,
    'description': profile.description,
    'anthropicConfig': profile.anthropicConfig?.toJson(),
    'openaiConfig': profile.openaiConfig?.toJson(),
    'azureOpenAIConfig': profile.azureOpenAIConfig?.toJson(),
    'togetherAIConfig': profile.togetherAIConfig?.toJson(),
    'tmuxConfig': profile.tmuxConfig?.toJson(),
    'environmentVariables':
        profile.environmentVariables.map((value) => value.toJson()).toList(),
    'defaultSessionType': profile.defaultSessionType?.value,
    'defaultPermissionMode': profile.defaultPermissionMode?.value,
    'defaultModelMode': profile.defaultModelMode,
    'compatibility': profile.compatibility.toJson(),
    'isBuiltIn': profile.isBuiltIn,
    'createdAt': profile.createdAt.millisecondsSinceEpoch,
    'updatedAt': profile.updatedAt.millisecondsSinceEpoch,
    'version': profile.version,
  };
}

AIProfile _aiProfileFromJson(Map<String, dynamic> json) {
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
            json['azureOpenAIConfig'] as Map<String, dynamic>,
          )
        : null,
    togetherAIConfig: json['togetherAIConfig'] != null
        ? TogetherAIConfig.fromJson(
            json['togetherAIConfig'] as Map<String, dynamic>,
          )
        : null,
    tmuxConfig: json['tmuxConfig'] != null
        ? TmuxConfig.fromJson(json['tmuxConfig'] as Map<String, dynamic>)
        : null,
    environmentVariables: (json['environmentVariables'] as List?)
            ?.map(
              (value) =>
                  EnvironmentVariable.fromJson(value as Map<String, dynamic>),
            )
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
    createdAt: createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
        : null,
    updatedAt: updatedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedAt)
        : null,
    version: json['version'] as String? ?? '1.0.0',
  );
}
