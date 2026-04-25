part of 'profile_list_screen.dart';

AIProfile _createProfileFromEditResult(Map<String, dynamic> result) {
  final providerType = result['providerType'] as String?;
  var name = result['name'] as String?;
  final description = result['description'] as String?;

  AnthropicConfig? anthropicConfig;
  OpenAIConfig? openaiConfig;
  AzureOpenAIConfig? azureOpenAIConfig;
  TogetherAIConfig? togetherAIConfig;

  switch (providerType) {
    case 'anthropic':
      name ??= 'Anthropic';
      anthropicConfig = AnthropicConfig(
        baseUrl: result['baseUrl'] as String?,
        authToken: result['authToken'] as String?,
        model: result['model'] as String?,
      );
      break;
    case 'openai':
      name ??= 'OpenAI';
      openaiConfig = OpenAIConfig(
        apiKey: result['apiKey'] as String?,
        baseUrl: result['baseUrl'] as String?,
        model: result['model'] as String?,
      );
      break;
    case 'azure':
      name ??= 'Azure OpenAI';
      azureOpenAIConfig = AzureOpenAIConfig(
        apiKey: result['apiKey'] as String?,
        endpoint: result['endpoint'] as String?,
        apiVersion: result['apiVersion'] as String?,
        deploymentName: result['deploymentName'] as String?,
      );
      break;
    case 'together':
      name ??= 'Together AI';
      togetherAIConfig = TogetherAIConfig(
        apiKey: result['apiKey'] as String?,
        model: result['model'] as String?,
      );
      break;
  }

  return AIProfile(
    id: const Uuid().v4(),
    name: name ?? 'AI Profile',
    description: description,
    anthropicConfig: anthropicConfig,
    openaiConfig: openaiConfig,
    azureOpenAIConfig: azureOpenAIConfig,
    togetherAIConfig: togetherAIConfig,
    defaultPermissionMode: result['permissionMode'] as PermissionMode?,
    defaultSessionType: result['sessionType'] as SessionType?,
    compatibility: const ProfileCompatibility(),
  );
}

AIProfile _updateProfileFromEditResult(
  AIProfile profile,
  Map<String, dynamic> result,
) {
  final providerType = result['providerType'] as String?;
  var anthropicConfig = profile.anthropicConfig;
  var openaiConfig = profile.openaiConfig;
  var azureOpenAIConfig = profile.azureOpenAIConfig;
  var togetherAIConfig = profile.togetherAIConfig;

  switch (providerType) {
    case 'anthropic':
      anthropicConfig = anthropicConfig?.copyWith(
        baseUrl: result['baseUrl'] as String?,
        authToken: result['authToken'] as String?,
        model: result['model'] as String?,
      );
      break;
    case 'openai':
      openaiConfig = openaiConfig?.copyWith(
        apiKey: result['apiKey'] as String?,
        baseUrl: result['baseUrl'] as String?,
        model: result['model'] as String?,
      );
      break;
    case 'azure':
      azureOpenAIConfig = azureOpenAIConfig?.copyWith(
        apiKey: result['apiKey'] as String?,
        endpoint: result['endpoint'] as String?,
        apiVersion: result['apiVersion'] as String?,
        deploymentName: result['deploymentName'] as String?,
      );
      break;
    case 'together':
      togetherAIConfig = togetherAIConfig?.copyWith(
        apiKey: result['apiKey'] as String?,
        model: result['model'] as String?,
      );
      break;
  }

  return profile.copyWith(
    name: result['name'] as String? ?? profile.name,
    description: result['description'] as String?,
    anthropicConfig: anthropicConfig,
    openaiConfig: openaiConfig,
    azureOpenAIConfig: azureOpenAIConfig,
    togetherAIConfig: togetherAIConfig,
    defaultPermissionMode: result['permissionMode'] as PermissionMode?,
    defaultSessionType: result['sessionType'] as SessionType?,
  );
}

IconData _providerIconForProfile(AIProfile profile) {
  switch (profile.providerType) {
    case 'anthropic':
      return Icons.psychology;
    case 'openai':
      return Icons.smart_toy;
    case 'azure':
      return Icons.cloud;
    case 'together':
      return Icons.auto_awesome;
    default:
      return Icons.settings;
  }
}
