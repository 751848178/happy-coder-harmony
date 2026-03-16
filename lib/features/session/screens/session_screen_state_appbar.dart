part of 'session_screen.dart';

extension _SessionScreenStateAppBar on _SessionScreenState {
  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('${AppRoutes.home}?tab=sessions');
  }

  /// 应用栏
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Session? session, {
    required List<_MessageTurnGroup> turnGroups,
    required bool showOverviewToggle,
  }) {
    final metadata = session?.metadata ?? const <String, dynamic>{};
    final subtitle = _formatPathForDisplay(
      metadata['path']?.toString() ?? session?.path ?? '',
      metadata['homeDir']?.toString(),
    );
    final title = _resolveHeaderTitle(session);

    return AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty || session?.active == true)
            Row(
              children: [
                if (session?.active == true) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    subtitle.isNotEmpty
                        ? subtitle
                        : (session?.active == true ? '活跃中' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: session?.active == true
                          ? AppTheme.successColor
                          : AppTheme.neutral600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () =>
              context.push(AppRoutes.sessionInfoDetail(widget.sessionId)),
          tooltip: '会话信息',
        ),
        if (showOverviewToggle)
          IconButton(
            icon: Icon(
              _sessionOverviewCollapsed
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
            ),
            onPressed: () {
              _updateState(() {
                _sessionOverviewCollapsed = !_sessionOverviewCollapsed;
              });
              unawaited(_persistSessionUiState());
            },
            tooltip: _sessionOverviewCollapsed ? '展开会话信息' : '收起会话信息',
          ),
        if (turnGroups.isNotEmpty)
          IconButton(
            icon: Icon(
              _collapseAllTurns
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
            ),
            onPressed: () => _toggleAllTurns(turnGroups),
            tooltip: _collapseAllTurns ? '展开全部轮次' : '按轮次折叠',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameDialog(session);
                break;
              case 'clone':
                _openCloneSession(session);
                break;
              case 'git':
                context.push(AppRoutes.sessionGitDetail(widget.sessionId));
                break;
              case 'info':
                context.push(AppRoutes.sessionInfoDetail(widget.sessionId));
                break;
              case 'clear':
                _showClearDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.drive_file_rename_outline, size: 18),
                  SizedBox(width: 12),
                  Text('修改名称'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clone',
              child: Row(
                children: [
                  Icon(Icons.control_point_duplicate_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('克隆会话'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'git',
              child: Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Git 仓库'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('会话详情'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 12),
                  Text('清空消息'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
