import 'package:json_annotation/json_annotation.dart';

part 'profile_models.g.dart';

/// AI 后端配置档案 (Backend Profile)
///
/// 用于配置不同 AI 提供商的环境变量和参数
@JsonSerializable()
class AIBackendProfile {
  final String id;
  final String name;
  final String? description;
  final AnthropicConfig? anthropicConfig;
  final OpenAIConfig? openaiConfig;
  final AzureOpenAIConfig? azureOpenAIConfig;
  final TmuxConfig? tmuxConfig;
  final TogetherAIConfig? togetherAIConfig;
  final List<EnvironmentVariable> environmentVariables;
  final String? defaultSessionType;
  final String? defaultPermissionMode;
  final String? defaultModelMode;
  final ProfileCompatibility compatibility;
  final bool isBuiltIn;
  final int createdAt;
  final int updatedAt;
  final String version;

  const AIBackendProfile({
    required this.id,
    required this.name,
    this.description,
    this.anthropicConfig,
    this.openaiConfig,
    this.azureOpenAIConfig,
    this.tmuxConfig,
    this.togetherAIConfig,
    required this.environmentVariables,
    this.defaultSessionType,
    this.defaultPermissionMode,
    this.defaultModelMode,
    required this.compatibility,
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory AIBackendProfile.fromJson(Map<String, dynamic> json) =>
      _$AIBackendProfileFromJson(json);

  Map<String, dynamic> toJson() => _$AIBackendProfileToJson(this);

  AIBackendProfile copyWith({
    String? id,
    String? name,
    String? description,
    AnthropicConfig? anthropicConfig,
    OpenAIConfig? openaiConfig,
    AzureOpenAIConfig? azureOpenAIConfig,
    TmuxConfig? tmuxConfig,
    TogetherAIConfig? togetherAIConfig,
    List<EnvironmentVariable>? environmentVariables,
    String? defaultSessionType,
    String? defaultPermissionMode,
    String? defaultModelMode,
    ProfileCompatibility? compatibility,
    bool? isBuiltIn,
    int? createdAt,
    int? updatedAt,
    String? version,
  }) {
    return AIBackendProfile(
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
      defaultPermissionMode: defaultPermissionMode ?? this.defaultPermissionMode,
      defaultModelMode: defaultModelMode ?? this.defaultModelMode,
      compatibility: compatibility ?? this.compatibility,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

/// Anthropic 配置
@JsonSerializable()
class AnthropicConfig {
  final String? baseUrl;
  final String? authToken;
  final String? model;

  const AnthropicConfig({
    this.baseUrl,
    this.authToken,
    this.model,
  });

  factory AnthropicConfig.fromJson(Map<String, dynamic> json) =>
      _$AnthropicConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AnthropicConfigToJson(this);
}

/// OpenAI 配置
@JsonSerializable()
class OpenAIConfig {
  final String? apiKey;
  final String? baseUrl;
  final String? model;

  const OpenAIConfig({
    this.apiKey,
    this.baseUrl,
    this.model,
  });

  factory OpenAIConfig.fromJson(Map<String, dynamic> json) =>
      _$OpenAIConfigFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIConfigToJson(this);
}

/// Azure OpenAI 配置
@JsonSerializable()
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

  factory AzureOpenAIConfig.fromJson(Map<String, dynamic> json) =>
      _$AzureOpenAIConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AzureOpenAIConfigToJson(this);
}

/// Together AI 配置
@JsonSerializable()
class TogetherAIConfig {
  final String? apiKey;
  final String? model;

  const TogetherAIConfig({
    this.apiKey,
    this.model,
  });

  factory TogetherAIConfig.fromJson(Map<String, dynamic> json) =>
      _$TogetherAIConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TogetherAIConfigToJson(this);
}

/// Tmux 配置
@JsonSerializable()
class TmuxConfig {
  final String? sessionName;
  final String? tmpDir;
  final bool? updateEnvironment;

  const TmuxConfig({
    this.sessionName,
    this.tmpDir,
    this.updateEnvironment,
  });

  factory TmuxConfig.fromJson(Map<String, dynamic> json) =>
      _$TmuxConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TmuxConfigToJson(this);
}

/// 环境变量
@JsonSerializable()
class EnvironmentVariable {
  final String name;
  final String value;

  const EnvironmentVariable({
    required this.name,
    required this.value,
  });

  factory EnvironmentVariable.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentVariableFromJson(json);

  Map<String, dynamic> toJson() => _$EnvironmentVariableToJson(this);

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

/// 档兼容性
@JsonSerializable()
class ProfileCompatibility {
  final bool claude;
  final bool codex;
  final bool gemini;

  const ProfileCompatibility({
    this.claude = true,
    this.codex = true,
    this.gemini = true,
  });

  factory ProfileCompatibility.fromJson(Map<String, dynamic> json) =>
      _$ProfileCompatibilityFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileCompatibilityToJson(this);
}

/// 创建/更新档案请求
@JsonSerializable()
class ProfileRequest {
  final String? id;
  final String name;
  final String? description;
  final AnthropicConfig? anthropicConfig;
  final OpenAIConfig? openaiConfig;
  final AzureOpenAIConfig? azureOpenAIConfig;
  final TmuxConfig? tmuxConfig;
  final TogetherAIConfig? togetherAIConfig;
  final List<EnvironmentVariable>? environmentVariables;
  final String? defaultSessionType;
  final String? defaultPermissionMode;
  final String? defaultModelMode;
  final ProfileCompatibility? compatibility;

  ProfileRequest copyWith({
    this.id,
    this.name,
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

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (id != null) json['id'] = id;
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (anthropicConfig != null) json['anthropicConfig'] = anthropicConfig!.toJson();
    if (openaiConfig != null) json['openaiConfig'] = openaiConfig!.toJson();
    if (azureOpenAIConfig != null) json['azureOpenAIConfig'] = azureOpenAIConfig!.toJson();
    if (tmuxConfig != null) json['tmuxConfig'] = tmuxConfig!.toJson();
    if (togetherAIConfig != null) json['togetherAIConfig'] = togetherAIConfig!.toJson();
    if (environmentVariables != null) {
      json['environmentVariables'] =
          environmentVariables.map((v) => v.toJson()).toList();
    }
    if (defaultSessionType != null) json['defaultSessionType'] = defaultSessionType;
    if (defaultPermissionMode != null) json['defaultPermissionMode'] = defaultPermissionMode;
    if (defaultModelMode != null) json['defaultModelMode'] = defaultModelMode;
    if (compatibility != null) json['compatibility'] = compatibility!.toJson();
    return json;
  }
}

/// 档案列表响应
@JsonSerializable()
class ProfileListResponse {
  final List<AIBackendProfile> items;

  const ProfileListResponse({required this.items});

  factory ProfileListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileListResponseToJson(this);
}
