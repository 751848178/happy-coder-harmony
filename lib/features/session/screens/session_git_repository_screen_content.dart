part of 'session_git_repository_screen.dart';

Widget _buildSessionGitRepositoryScreen(
    _SessionGitRepositoryScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Git 仓库'),
          if (state._session != null)
            Text(
              state._session!.title,
              style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: '查看改动文件',
          onPressed: () => state.context.push(
            AppRoutes.sessionFilesDetail(state.widget.sessionId),
          ),
          icon: const Icon(Icons.compare_arrows_outlined),
        ),
        IconButton(
          tooltip: '刷新',
          onPressed: state._loadRepository,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _buildSessionGitRepositoryBody(state, state._data),
  );
}

Widget _buildSessionGitRepositoryBody(
  _SessionGitRepositoryScreenState state,
  SessionProjectRepositoryData? data,
) {
  if (state._isLoading) {
    return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandColor));
  }
  if (state._error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          state._error!,
          style: const TextStyle(color: AppTheme.neutral700, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  if (data == null) {
    return const SizedBox.shrink();
  }

  final visibleFiles = _visibleRepositoryFiles(state, data);
  final treeNodes = _buildRepositoryTreeNodes(visibleFiles);
  final forceExpandAll = state._searchController.text.trim().isNotEmpty;
  return RefreshIndicator(
    onRefresh: state._loadRepository,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildRepositorySummaryCard(data),
        const SizedBox(height: 16),
        _buildRepositorySearchField(state),
        const SizedBox(height: 12),
        _buildRepositoryFilterBar(state, data.repository),
        const SizedBox(height: 12),
        if (!data.usedRpc || data.repository.fromDerivedData)
          _buildRepositorySourceBanner(data.repository.sourceLabel),
        if (!data.usedRpc || data.repository.fromDerivedData)
          const SizedBox(height: 12),
        if (visibleFiles.isEmpty)
          _buildRepositoryEmptyState(data)
        else
          ..._buildRepositoryTreeWidgets(
            state,
            treeNodes,
            depth: 0,
            forceExpandAll: forceExpandAll,
          ),
      ],
    ),
  );
}

Widget _buildRepositorySummaryCard(SessionProjectRepositoryData data) {
  final repository = data.repository;
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
        _buildRepositorySummaryHeader(repository),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
                label: '${data.projectFiles.length} 个仓库文件',
                color: AppTheme.infoColor),
            _SummaryChip(
                label: '${repository.totalChangedFiles} 个改动文件',
                color: AppTheme.brandColor),
            _SummaryChip(
                label: '+${repository.totalAddedLines} 行',
                color: AppTheme.successColor),
            _SummaryChip(
                label: '-${repository.totalRemovedLines} 行',
                color: AppTheme.errorColor),
          ],
        ),
      ],
    ),
  );
}

Widget _buildRepositorySearchField(_SessionGitRepositoryScreenState state) {
  return TextField(
    controller: state._searchController,
    onChanged: (_) => state._updateView(() {}),
    decoration: InputDecoration(
      hintText: '搜索仓库文件',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
