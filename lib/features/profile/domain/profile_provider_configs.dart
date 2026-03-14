part of 'profile_models.dart';

/// Anthropic AI provider configuration
class AnthropicConfig {
  final String? baseUrl;
  final String? authToken;
  final String? model;

  const AnthropicConfig({this.baseUrl, this.authToken, this.model});

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'authToken': authToken,
        'model': model,
      };

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

  const OpenAIConfig({this.apiKey, this.baseUrl, this.model});

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
      };

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

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'endpoint': endpoint,
        'apiVersion': apiVersion,
        'deploymentName': deploymentName,
      };

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

  const TogetherAIConfig({this.apiKey, this.model});

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'model': model,
      };

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

  Map<String, dynamic> toJson() => {
        'sessionName': sessionName,
        'tmpDir': tmpDir,
        'updateEnvironment': updateEnvironment,
      };

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
