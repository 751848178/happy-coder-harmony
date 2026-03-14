part of 'glob_tool_screen.dart';

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onSampleSearch});

  final VoidCallback onSampleSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              '文件模式匹配',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入 Glob 模式来查找文件',
              style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onSampleSearch,
              icon: const Icon(Icons.play_arrow),
              label: const Text('尝试示例搜索'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.pattern});

  final String pattern;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            '未找到匹配项',
            style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
          ),
          const SizedBox(height: 8),
          Text(
            '模式: $pattern',
            style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '搜索失败',
              style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.pattern, required this.description});

  final String pattern;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pattern,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
          ),
        ],
      ),
    );
  }
}
