part of 'session_git_repository_screen.dart';

Widget _buildRepositorySummaryHeader(SessionGitRepositoryView repository) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Icon(Icons.account_tree_outlined, color: AppTheme.brandColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repository.branch,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              repository.rootPath.isEmpty
                  ? '当前会话未返回工作区路径'
                  : repository.rootPath,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildRepositoryFilterBar(
  _SessionGitRepositoryScreenState state,
  SessionGitRepositoryView repository,
) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _FilterChipButton(
        label: '全部',
        selected: state._filter == _RepositoryFilter.all,
        onTap: () =>
            state._updateView(() => state._filter = _RepositoryFilter.all),
      ),
      _FilterChipButton(
        label: '仅改动',
        selected: state._filter == _RepositoryFilter.changed,
        onTap: () =>
            state._updateView(() => state._filter = _RepositoryFilter.changed),
      ),
      _FilterChipButton(
        label: '已暂存 ${repository.stagedFiles.length}',
        selected: state._filter == _RepositoryFilter.staged,
        onTap: () =>
            state._updateView(() => state._filter = _RepositoryFilter.staged),
      ),
      _FilterChipButton(
        label: '未暂存 ${repository.unstagedFiles.length}',
        selected: state._filter == _RepositoryFilter.unstaged,
        onTap: () =>
            state._updateView(() => state._filter = _RepositoryFilter.unstaged),
      ),
    ],
  );
}

Widget _buildRepositorySourceBanner(String sourceLabel) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.warningColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.2)),
    ),
    child: Text(
      '$sourceLabel。当前仍会优先使用真实仓库 RPC；只有在 RPC 不可用时才回退到会话消息推断。',
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: AppTheme.neutral700,
      ),
    ),
  );
}

Widget _buildRepositoryEmptyState(SessionProjectRepositoryData data) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppTheme.neutral200),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.folder_open_outlined,
          size: 48,
          color: AppTheme.neutral500,
        ),
        const SizedBox(height: 12),
        const Text(
          '当前筛选条件下没有文件',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.projectFiles.isEmpty ? '当前没有拿到仓库文件列表。' : '换个关键词，或者切换筛选项继续查看。',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
