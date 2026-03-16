part of 'model_selector.dart';

class ModelOption {
  const ModelOption({
    required this.id,
    required this.name,
    required this.displayName,
    this.model,
    this.maxTokens,
    this.contextWindow,
  });

  final String id;
  final String name;
  final String displayName;
  final String? model;
  final int? maxTokens;
  final String? contextWindow;

  static List<ModelOption> getOptionsForProvider(String providerId) {
    switch (providerId) {
      case 'anthropic':
        return const [
          ModelOption(
              id: 'claude-3.5-sonnet',
              name: 'Claude 3.5 Sonnet',
              displayName: 'Claude 3.5 Sonnet',
              model: 'claude-3-5-sonnet',
              maxTokens: 200000,
              contextWindow: '200K tokens'),
          ModelOption(
              id: 'claude-3-opus',
              name: 'Claude 3.5 Opus',
              displayName: 'Claude 3.5 Opus',
              model: 'claude-3-5-opus',
              maxTokens: 200000,
              contextWindow: '200K tokens'),
          ModelOption(
              id: 'claude-3-haiku',
              name: 'Claude 3.5 Haiku',
              displayName: 'Claude 3.5 Haiku',
              model: 'claude-3-5-haiku',
              maxTokens: 200000,
              contextWindow: '200K tokens'),
        ];
      case 'openai':
        return const [
          ModelOption(
              id: 'gpt-4o',
              name: 'GPT-4o',
              displayName: 'GPT-4o',
              model: 'gpt-4o',
              maxTokens: 128000,
              contextWindow: '128K tokens'),
          ModelOption(
              id: 'gpt-4-turbo',
              name: 'GPT-4 Turbo',
              displayName: 'GPT-4 Turbo',
              model: 'gpt-4-turbo',
              maxTokens: 128000,
              contextWindow: '128K tokens'),
          ModelOption(
              id: 'gpt-4-32k',
              name: 'GPT-4 32K',
              displayName: 'GPT-4 32K',
              model: 'gpt-4-32k',
              maxTokens: 128000,
              contextWindow: '32K tokens'),
          ModelOption(
              id: 'o1-preview',
              name: 'o1-preview',
              displayName: 'o1-preview',
              model: 'o1-preview',
              maxTokens: 32000,
              contextWindow: '128K tokens'),
          ModelOption(
              id: 'o1-mini',
              name: 'o1-mini',
              displayName: 'o1-mini',
              model: 'o1-mini',
              maxTokens: 16384,
              contextWindow: '128K tokens'),
          ModelOption(
              id: 'o3-mini',
              name: 'o3-mini',
              displayName: 'o3-mini',
              model: 'o3-mini',
              maxTokens: 16384,
              contextWindow: '128K tokens'),
        ];
      case 'azure':
        return const [
          ModelOption(
              id: 'gpt-4o',
              name: 'GPT-4o (Azure)',
              displayName: 'GPT-4o Azure',
              model: 'gpt-4o',
              maxTokens: 128000,
              contextWindow: '128K tokens'),
        ];
      case 'together':
        return const [
          ModelOption(
              id: 'mistral-7b-instruct-v0.1',
              name: 'Mixtral 7B',
              displayName: 'Mixtral 7B',
              model: 'mistralai/Mixtral-7b-instruct-v0.1',
              maxTokens: 32768,
              contextWindow: '32K tokens'),
          ModelOption(
              id: 'mixtral-8x7b-instruct-v0.1',
              name: 'Mixtral 8x7B',
              displayName: 'Mixtral 8x7B',
              model: 'mixtral-8x7b-instruct-v0.1',
              maxTokens: 32768,
              contextWindow: '32K tokens'),
          ModelOption(
              id: 'llama-3-70b-instruct',
              name: 'Llama 3 1B',
              displayName: 'Llama 3.1B',
              model: 'llama-3-1b',
              maxTokens: 32768,
              contextWindow: '8K tokens'),
        ];
      default:
        return const [];
    }
  }
}
