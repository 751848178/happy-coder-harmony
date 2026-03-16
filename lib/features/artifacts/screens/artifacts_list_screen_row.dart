part of 'artifacts_list_screen.dart';

class _ArtifactRow extends StatelessWidget {
  const _ArtifactRow({
    required this.artifact,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Artifact artifact;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(isFirst ? 12 : 0),
      bottom: Radius.circular(isLast ? 12 : 0),
    );

    return Material(
      color: AppTheme.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: AppTheme.brandColor),
              const SizedBox(width: 12),
              Expanded(child: _ArtifactRowText(artifact: artifact)),
              const Icon(Icons.chevron_right, color: AppTheme.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtifactRowText extends StatelessWidget {
  const _ArtifactRowText({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          artifactDisplayTitle(artifact),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(artifact.updatedAt),
          style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp)
        .toLocal()
        .toString()
        .substring(0, 16);
  }
}
