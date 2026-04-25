part of 'ls_tool_screen.dart';

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.totalEntries,
    required this.directories,
    required this.files,
  });

  final int totalEntries;
  final int directories;
  final int files;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.neutral100,
      child: Row(
        children: [
          _StatItem(label: '总计', value: totalEntries.toString()),
          const SizedBox(width: 16),
          _StatItem(
            label: '目录',
            value: directories.toString(),
            color: AppTheme.brandColor,
          ),
          const SizedBox(width: 16),
          _StatItem(
            label: '文件',
            value: files.toString(),
            color: AppTheme.neutral600,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: AppTheme.neutral600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.path,
    required this.onRetry,
  });

  final String path;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              '目录为空',
              style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
            ),
            const SizedBox(height: 8),
            Text(
              path,
              style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ),
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
              '加载失败',
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
