part of 'model_selector.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  final List<ModelOption> options;
  final ModelOption? selectedOption;
  final ValueChanged<ModelOption> onChanged;

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
            onSelected: () => onChanged(option),
          );
        }).toList(),
      ),
    );
  }
}

class _ModelOptionChip extends StatelessWidget {
  const _ModelOptionChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

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

class ContextSizeDisplay extends StatelessWidget {
  const ContextSizeDisplay({
    super.key,
    required this.maxTokens,
    required this.contextWindow,
  });

  final int maxTokens;
  final String contextWindow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.memory_outlined, size: 18, color: AppTheme.neutral600),
        const SizedBox(width: 8),
        Text('上下文', style: TextStyle(fontSize: 13, color: AppTheme.neutral600)),
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
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 16),
        Text(contextWindow,
            style: TextStyle(fontSize: 12, color: AppTheme.neutral600)),
      ],
    );
  }
}
