part of 'session_files_browser_screen.dart';

PreferredSizeWidget _buildSessionFilesBrowserAppBar(
  _SessionFilesBrowserScreenState state,
) {
  final session = state._session;
  return AppBar(
    backgroundColor: AppTheme.surface,
    foregroundColor: AppTheme.textPrimary,
    elevation: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('会话文件'),
        if (session != null)
          Text(
            session.title,
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: '查看完整仓库',
        onPressed: () => state.context.push(
          AppRoutes.sessionGitDetail(state.widget.sessionId),
        ),
        icon: const Icon(Icons.account_tree_outlined),
      ),
      IconButton(
        tooltip: '刷新',
        onPressed: state._loadFiles,
        icon: const Icon(Icons.refresh),
      ),
    ],
  );
}

Widget _buildSessionFilesBrowserBody(
  _SessionFilesBrowserScreenState state,
  SessionProjectRepositoryData? data,
) {
  if (state._isLoading) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.brandColor),
    );
  }
  if (state._error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          state._error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.neutral700, height: 1.6),
        ),
      ),
    );
  }
  if (data == null) {
    return const SizedBox.shrink();
  }
  final entries = _visibleEntries(state, data);
  return RefreshIndicator(
    onRefresh: state._loadFiles,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSessionFilesSummaryCard(data),
        const SizedBox(height: 16),
        _buildSessionFilesSearchField(state),
        const SizedBox(height: 12),
        if (!data.usedRpc || data.repository.fromDerivedData)
          _buildSessionFilesSourceBanner(data.repository.sourceLabel),
        if (!data.usedRpc || data.repository.fromDerivedData)
          const SizedBox(height: 12),
        if (entries.isEmpty)
          _buildSessionFilesEmptyState(state)
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChangedFileTile(
                entry: entry,
                onTap: () => _openSessionFileEntry(state, entry),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildSessionFilesSearchField(_SessionFilesBrowserScreenState state) {
  return TextField(
    controller: state._searchController,
    onChanged: (_) => state._updateView(() {}),
    decoration: InputDecoration(
      hintText: '搜索改动文件名或路径',
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
