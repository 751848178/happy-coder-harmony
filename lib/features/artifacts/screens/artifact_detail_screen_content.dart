part of 'artifact_detail_screen.dart';

extension _ArtifactDetailScreenContent on _ArtifactDetailScreenState {
  Widget _buildBody(Artifact? artifact) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor),
      );
    }

    if (_error != null || artifact == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? '工件不存在',
            style: const TextStyle(
              color: AppTheme.neutral600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final body = artifact.body?.trim();
    final description = artifactDisplayDescription(artifact);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          artifactDisplayTitle(artifact),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTimestamp(artifact.updatedAt),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutral700,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: body == null || body.isEmpty
              ? const Text(
                  'No content',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.neutral600,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : MarkdownBody(
                  data: body,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppTheme.textPrimary,
                    ),
                    code: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  String _formatTimestamp(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
