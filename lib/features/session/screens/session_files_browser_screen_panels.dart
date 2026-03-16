part of 'session_files_browser_screen.dart';

Widget _buildSessionFilesSummaryCard(SessionProjectRepositoryData data) {
  final uniqueChangedCount = {
    ...data.repository.stagedFiles.map((file) => file.path),
    ...data.repository.unstagedFiles.map((file) => file.path),
  }.length;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '当前会话改动文件',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.repository.rootPath.isEmpty
              ? '当前会话没有返回工作区路径'
              : data.repository.rootPath,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              label: '$uniqueChangedCount 个改动文件',
              color: AppTheme.brandColor,
            ),
            _SummaryChip(
              label: '已暂存 ${data.repository.stagedFiles.length}',
              color: AppTheme.successColor,
            ),
            _SummaryChip(
              label: '未暂存 ${data.repository.unstagedFiles.length}',
              color: AppTheme.warningColor,
            ),
            _SummaryChip(
              label:
                  '+${data.repository.totalAddedLines} / -${data.repository.totalRemovedLines}',
              color: AppTheme.infoColor,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSessionFilesSourceBanner(String sourceLabel) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.warningColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(
        color: AppTheme.warningColor.withValues(alpha: 0.2),
      ),
    ),
    child: Text(
      '$sourceLabel。当前会话文件页会优先展示真实 Git 改动；只有在仓库 RPC 不可用时才回退到会话消息推断。',
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: AppTheme.neutral700,
      ),
    ),
  );
}

Widget _buildSessionFilesEmptyState(_SessionFilesBrowserScreenState state) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      children: [
        const Icon(Icons.task_alt_outlined,
            size: 48, color: AppTheme.neutral500),
        const SizedBox(height: 12),
        const Text(
          '当前没有检测到改动文件',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '如果你想查看整个仓库文件列表，可以进入 Git 仓库页面继续浏览。',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 12, color: AppTheme.neutral600, height: 1.6),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => state.context.push(
            AppRoutes.sessionGitDetail(state.widget.sessionId),
          ),
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('打开 Git 仓库'),
        ),
      ],
    ),
  );
}
