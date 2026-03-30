part of 'session_screen.dart';

extension _SessionScreenViewOverview on _SessionScreenState {
  Widget _buildSessionOverview(Session session, SessionStats sessionStats) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final host = metadata['host']?.toString();
    final flavor = _resolveFlavorLabel(metadata['flavor']?.toString());
    final version = metadata['version']?.toString();
    final workingDirectory = _formatPathForDisplay(
      metadata['path']?.toString() ?? session.path ?? '',
      metadata['homeDir']?.toString(),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workingDirectory.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: AppTheme.neutral600,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    workingDirectory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.memory_rounded,
                  label: flavor,
                  color: AppTheme.brandColor,
                ),
                if (host != null && host.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.computer_rounded,
                    label: host,
                    color: AppTheme.infoColor,
                  ),
                ],
                if (version != null && version.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.code_rounded,
                    label: version,
                    color: AppTheme.successColor,
                  ),
                ],
                if (sessionStats.hasChanges) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  _InfoChip(
                    icon: Icons.edit_note_rounded,
                    label: '${sessionStats.changedLineCount} 行改动',
                    color: AppTheme.warningColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: 16),
            const Text(
              '这个会话已经不存在了',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '它可能已经被删除，或者还没有同步完成。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _handleBackNavigation,
              child: const Text('返回会话列表'),
            ),
          ],
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '开始新的对话',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '发送消息开始与 AI 助手对话',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// 消息列表
}
