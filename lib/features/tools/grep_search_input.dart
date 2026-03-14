part of 'grep_tool_screen.dart';

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.patternController,
    required this.pathController,
    required this.caseSensitive,
    required this.useRegex,
    required this.onCaseSensitiveChanged,
    required this.onUseRegexChanged,
    required this.onSearch,
  });

  final TextEditingController patternController;
  final TextEditingController pathController;
  final bool caseSensitive;
  final bool useRegex;
  final ValueChanged<bool> onCaseSensitiveChanged;
  final ValueChanged<bool> onUseRegexChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: patternController,
            decoration: InputDecoration(
              labelText: useRegex ? '正则表达式' : '搜索内容',
              hintText: useRegex ? '例如: class \\w+' : '例如: MyApp',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: patternController.clear,
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pathController,
            decoration: InputDecoration(
              labelText: '搜索路径',
              hintText: '默认: . (当前目录)',
              prefixIcon: const Icon(Icons.folder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('区分大小写'),
                selected: caseSensitive,
                onSelected: onCaseSensitiveChanged,
                avatar: Icon(
                  Icons.text_fields,
                  size: 16,
                  color: caseSensitive ? Colors.white : null,
                ),
                selectedColor: AppTheme.brandColor,
              ),
              FilterChip(
                label: const Text('使用正则'),
                selected: useRegex,
                onSelected: onUseRegexChanged,
                avatar: Icon(
                  Icons.code,
                  size: 16,
                  color: useRegex ? Colors.white : null,
                ),
                selectedColor: AppTheme.brandColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('搜索'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
