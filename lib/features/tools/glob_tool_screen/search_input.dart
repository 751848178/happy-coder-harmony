part of 'glob_tool_screen.dart';

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.patternController,
    required this.pathController,
    required this.onSearch,
  });

  final TextEditingController patternController;
  final TextEditingController pathController;
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
              labelText: '匹配模式',
              hintText: '例如: **/*.dart',
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
          Row(
            children: [
              Expanded(
                child: TextField(
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
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('搜索'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PatternChip(
                label: '*.dart',
                onTap: () {
                  patternController.text = '*.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: '**/*.dart',
                onTap: () {
                  patternController.text = '**/*.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: '**/*_test.dart',
                onTap: () {
                  patternController.text = '**/*_test.dart';
                  onSearch();
                },
              ),
              _PatternChip(
                label: 'pubspec.yaml',
                onTap: () {
                  patternController.text = 'pubspec.yaml';
                  onSearch();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatternChip extends StatelessWidget {
  const _PatternChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.code, size: 16),
      onPressed: onTap,
      backgroundColor: AppTheme.neutral100,
      labelStyle: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 12,
      ),
    );
  }
}
