import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Model options for AI providers
class ModelOption {
  final String id;
  final String name;
  final String displayName;
  final String? model;
  final int? maxTokens;
  final String? contextWindow; // e.g., "200K tokens"

  const ModelOption({
    required this.id,
    required this.name,
    required this.displayName,
    this.model,
    this.maxTokens,
    this.contextWindow,
  });

  /// Get all available model options for each provider
  static List<ModelOption> getOptionsForProvider(String providerId) {
    switch (providerId) {
      case 'anthropic':
        return [
          ModelOption(
            id: 'claude-3.5-sonnet',
            name: 'Claude 3.5 Sonnet',
            displayName: 'Claude 3.5 Sonnet',
            model: 'claude-3-5-sonnet',
            maxTokens: 200000,
            contextWindow: '200K tokens',
          ),
          ModelOption(
            id: 'claude-3-opus',
            name: 'Claude 3.5 Opus',
            displayName: 'Claude 3.5 Opus',
            model: 'claude-3-5-opus',
            maxTokens: 200000,
            contextWindow: '200K tokens',
          ),
          ModelOption(
            id: 'claude-3-haiku',
            name: 'Claude 3.5 Haiku',
            displayName: 'Claude 3.5 Haiku',
            model: 'claude-3-5-haiku',
            maxTokens: 200000,
            contextWindow: '200K tokens',
          ),
        ];
      case 'openai':
        return [
          ModelOption(
            id: 'gpt-4o',
            name: 'GPT-4o',
            displayName: 'GPT-4o',
            model: 'gpt-4o',
            maxTokens: 128000,
            contextWindow: '128K tokens',
          ),
          ModelOption(
            id: 'gpt-4-turbo',
            name: 'GPT-4 Turbo',
            displayName: 'GPT-4 Turbo',
            model: 'gpt-4-turbo',
            maxTokens: 128000,
            contextWindow: '128K tokens',
          ),
          ModelOption(
            id: 'gpt-4-32k',
            name: 'GPT-4 32K',
            displayName: 'GPT-4 32K',
            model: 'gpt-4-32k',
            maxTokens: 128000,
            contextWindow: '32K tokens',
          ),
          ModelOption(
            id: 'o1-preview',
            name: 'o1-preview',
            displayName: 'o1-preview',
            model: 'o1-preview',
            maxTokens: 32000,
            contextWindow: '128K tokens',
          ),
          ModelOption(
            id: 'o1-mini',
            name: 'o1-mini',
            displayName: 'o1-mini',
            model: 'o1-mini',
            maxTokens: 16384,
            contextWindow: '128K tokens',
          ),
          ModelOption(
            id: 'o3-mini',
            name: 'o3-mini',
            displayName: 'o3-mini',
            model: 'o3-mini',
            maxTokens: 16384,
            contextWindow: '128K tokens',
          ),
        ];
      case 'azure':
        return [
          ModelOption(
            id: 'gpt-4o',
            name: 'GPT-4o (Azure)',
            displayName: 'GPT-4o Azure',
            model: 'gpt-4o',
            maxTokens: 128000,
            contextWindow: '128K tokens',
          ),
        ];
      case 'together':
        return [
          ModelOption(
            id: 'mistral-7b-instruct-v0.1',
            name: 'Mixtral 7B',
            displayName: 'Mixtral 7B',
            model: 'mistralai/Mixtral-7b-instruct-v0.1',
            maxTokens: 32768,
            contextWindow: '32K tokens',
          ),
          ModelOption(
            id: 'mixtral-8x7b-instruct-v0.1',
            name: 'Mixtral 8x7B',
            displayName: 'Mixtral 8x7B',
            model: 'mixtral-8x7b-instruct-v0.1',
            maxTokens: 32768,
            contextWindow: '32K tokens',
          ),
          ModelOption(
            id: 'llama-3-70b-instruct',
            name: 'Llama 3 1B',
            displayName: 'Llama 3.1B',
            model: 'llama-3-1b',
            maxTokens: 32768,
            contextWindow: '8K tokens',
          ),
        ];
      default:
        return [];
    }
  }
}

/// Model selector widget
class ModelSelector extends StatelessWidget {
  final List<ModelOption> options;
  final ModelOption? selectedOption;
  final ValueChanged<ModelOption> onChanged;

  const ModelSelector({
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.neutral300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        children: options.map((option) {
          final isSelected = selectedOption?.id == option.id;
          return _ModelOptionChip(
            label: option.displayName,
            isSelected: isSelected,
            onSelected: () {
              onChanged(option);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Model option chip widget
class _ModelOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ModelOptionChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: isSelected ? AppTheme.brandColor : null,
      checkmarkColor: isSelected ? Colors.white : null,
      backgroundColor: isSelected ? AppTheme.brandColor : AppTheme.neutral100,
      labelStyle: const TextStyle(fontSize: 14),
      avatar: const SizedBox(width: 24, height: 24),
    );
  }
}

/// Context size display widget
class ContextSizeDisplay extends StatelessWidget {
  final int maxTokens;
  final String contextWindow;

  const ContextSizeDisplay({
    required this.maxTokens,
    required this.contextWindow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.memory_outlined, size: 18, color: AppTheme.neutral600),
        const SizedBox(width: 8),
        Text(
          '上下文',
          style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$maxTokens tokens',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.brandColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          contextWindow,
          style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
        ),
      ],
    );
  }
}
