part of 'profile_models.dart';

/// Built-in profile templates
class BuiltInProfiles {
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

  static final mixtral8x7b = AIProfile(
    id: 'mixtral-8x7b',
    name: 'Mixtral 8x7B',
    description: '开源的高性能模型',
    togetherAIConfig: const TogetherAIConfig(
      model: 'mistral-8x7b-instruct-v0.1',
    ),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(),
    isBuiltIn: true,
  );

  static final llama370b = AIProfile(
    id: 'llama-3-1-70b',
    name: 'Llama 3.1 70B',
    description: 'Meta 的开源大语言模型',
    togetherAIConfig: const TogetherAIConfig(model: 'llama-3-1b'),
    defaultPermissionMode: PermissionMode.defaultMode,
    defaultSessionType: SessionType.simple,
    compatibility: const ProfileCompatibility(),
    isBuiltIn: true,
  );

  static final claudeDefault = claude35Sonnet;
  static final openaiDefault = gpt4o;

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

  static AIProfile get recommended => claude35Sonnet;

  static AIProfile? byId(String id) {
    try {
      return all().firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

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
