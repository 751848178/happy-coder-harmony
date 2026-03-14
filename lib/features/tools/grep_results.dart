part of 'grep_tool_screen.dart';

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(grepNotifierProvider);

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
        onRetry: () => ref.read(grepNotifierProvider.notifier).search(
              state.currentPattern,
              state.currentPath,
              caseSensitive: state.caseSensitive,
              useRegex: state.useRegex,
            ),
      );
    }

    if (state.matches.isEmpty && state.currentPattern.isEmpty) {
      return _EmptyView(
        onSampleSearch: () {
          ref.read(grepNotifierProvider.notifier).search('MyApp', '.');
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
                '找到 ${state.matches.length} 个匹配',
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
                      ref.read(grepNotifierProvider.notifier).clear(),
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

  final GrepMatch match;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${match.filePath}:${match.lineNumber}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 16, color: AppTheme.neutral500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.filePath,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '行 ${match.lineNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.brandColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${match.lineNumber}:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.lineContent,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
