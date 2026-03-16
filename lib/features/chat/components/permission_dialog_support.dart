part of 'permission_dialog.dart';

class _PermissionDialogTitle extends StatelessWidget {
  const _PermissionDialogTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.lock_outline, color: Colors.orange, size: 24),
        SizedBox(width: 12),
        Text('权限请求'),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.toolName,
    required this.arguments,
  });

  final String toolName;
  final Map<String, dynamic> arguments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PermissionSectionLabel(label: '工具'),
          const SizedBox(height: 8),
          Text(
            toolName,
            style: TextStyle(
              color: AppTheme.brandColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _PermissionSectionLabel(label: '参数'),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: arguments.entries
                .map((entry) => _PermissionArgumentRow(entry: entry))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PermissionSectionLabel extends StatelessWidget {
  const _PermissionSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.neutral600,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PermissionArgumentRow extends StatelessWidget {
  const _PermissionArgumentRow({required this.entry});

  final MapEntry<String, dynamic> entry;

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
              entry.key,
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.value.toString(),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
