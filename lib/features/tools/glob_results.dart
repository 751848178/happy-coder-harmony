part of 'glob_tool_screen.dart';

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(globNotifierProvider);

    if (state.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.brandColor),
            SizedBox(height: 16),
            Text('搜索中...', style: TextStyle(color: AppTheme.neutral600)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        errorMessage: state.error!,
        onRetry: () => ref.read(globNotifierProvider.notifier).search(
              state.currentPattern,
              state.currentPath,
            ),
      );
    }

    if (state.matches.isEmpty && state.currentPattern.isEmpty) {
      return _EmptyView(
        onSampleSearch: () {
          ref.read(globNotifierProvider.notifier).search('**/*.dart', '.');
        },
      );
    }

    if (state.matches.isEmpty) {
      return _NoResultsView(pattern: state.currentPattern);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.neutral100,
          child: Row(
            children: [
              Text(
                '找到 ${state.matches.length} 个匹配项',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.neutral700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (state.currentPattern.isNotEmpty)
                Chip(
                  label: Text(
                    state.currentPattern,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () =>
                      ref.read(globNotifierProvider.notifier).clear(),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: state.matches.length,
            itemBuilder: (context, index) {
              return _MatchItem(match: state.matches[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _MatchItem extends StatelessWidget {
  const _MatchItem({required this.match});

  final GlobMatch match;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选中: ${match.path}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
        ),
        child: Row(
          children: [
            Icon(
              match.isDirectory ? Icons.folder : Icons.insert_drive_file,
              color:
                  match.isDirectory ? AppTheme.brandColor : AppTheme.neutral500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.path,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: match.isDirectory
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (!match.isDirectory && match.size != null)
                    Text(
                      _formatSize(match.size!),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutral500,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.neutral400),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
