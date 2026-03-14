part of 'ls_tool_screen.dart';

class _PathBar extends ConsumerWidget {
  const _PathBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lsNotifierProvider);
    controller.text = state.currentPath;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: state.pathHistory.isEmpty && state.currentPath == '.'
                ? null
                : () => ref.read(lsNotifierProvider.notifier).navigateUp(),
            tooltip: '上级目录',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '当前路径',
                hintText: '.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (value) {
                ref.read(lsNotifierProvider.notifier).listDirectory(
                      value.trim().isEmpty ? '.' : value.trim(),
                    );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              ref.read(lsNotifierProvider.notifier).listDirectory(
                    controller.text.trim().isEmpty ? '.' : controller.text,
                  );
            },
            tooltip: '前往',
          ),
        ],
      ),
    );
  }
}

class _EntriesList extends ConsumerWidget {
  const _EntriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lsNotifierProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        errorMessage: state.error!,
        onRetry: () => ref.read(lsNotifierProvider.notifier).refresh(),
      );
    }

    if (state.entries.isEmpty) {
      return _EmptyView(
        path: state.currentPath,
        onRetry: () => ref.read(lsNotifierProvider.notifier).refresh(),
      );
    }

    return Column(
      children: [
        _StatsBar(
          totalEntries: state.entries.length,
          directories: state.entries.where((entry) => entry.isDirectory).length,
          files: state.entries.where((entry) => !entry.isDirectory).length,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.5 : 1.2,
                ),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  return _EntryCard(entry: state.entries[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
