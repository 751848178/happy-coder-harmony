part of 'ls_tool_screen.dart';

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final DirectoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (entry.isDirectory) {
          ref.read(lsNotifierProvider.notifier).listDirectory(entry.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开文件: ${entry.name}')),
          );
        }
      },
      onLongPress: () => _showEntryMenu(context, entry),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  entry.isDirectory ? Icons.folder : _getFileIcon(entry.name),
                  color: entry.isDirectory
                      ? AppTheme.brandColor
                      : AppTheme.neutral500,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: entry.isDirectory
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (!entry.isDirectory && entry.size != null)
              Text(
                _formatSize(entry.size!),
                style: TextStyle(fontSize: 11, color: AppTheme.neutral500),
              ),
            if (entry.modifiedAt != null)
              Text(
                _formatDate(entry.modifiedAt!),
                style: TextStyle(fontSize: 10, color: AppTheme.neutral400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
