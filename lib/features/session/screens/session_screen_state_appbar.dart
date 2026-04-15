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
        // Refresh icon — isolated rebuild via ValueNotifier.
        ValueListenableBuilder<bool>(
          valueListenable: _isRefreshingSessionStateN,
          builder: (_, isRefreshing, __) {
            return IgnorePointer(
              ignoring: isRefreshing,
              child: Opacity(
                opacity: isRefreshing ? 0.72 : 1,
                child: IconButton(
                  icon: RotationTransition(
                    turns: _refreshIconController,
                    child: Icon(
                      isRefreshing
                          ? Icons.sync_rounded
                          : Icons.refresh_rounded,
                    ),
                  ),
                  onPressed: _refreshSessionState,
                  tooltip: isRefreshing ? '刷新中' : '刷新会话',
                ),
              ),
            );
          },
        ),
        if (showOverviewToggle)
          ValueListenableBuilder<bool>(
            valueListenable: _sessionOverviewCollapsedN,
            builder: (_, collapsed, __) {
              return IconButton(
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                ),
                onPressed: () {
                  _sessionOverviewCollapsedN.value =
                      !_sessionOverviewCollapsedN.value;
                  unawaited(_persistSessionUiState());
                },
                tooltip: collapsed ? '展开会话信息' : '收起会话信息',
              );
            },
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
              case 'sync_messages':
                unawaited(_syncSessionMessagesFromRemote());
                break;
              case 'clear':
                _showClearDialog();
                break;
              case 'local_service':
                _openLocalService(session);
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
            PopupMenuItem(
              value: 'sync_messages',
              enabled: !_isSyncingAllMessagesN.value,
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: _isSyncingAllMessagesN.value
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.cloud_sync_outlined, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isSyncingAllMessagesN.value ? '同步中...' : '同步全部消息',
                  ),
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
            const PopupMenuItem(
              value: 'local_service',
              child: Row(
                children: [
                  Icon(Icons.language, size: 18),
                  SizedBox(width: 12),
                  Text('本地服务'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openLocalService(Session? session) {
    if (session == null || session.id.isEmpty) return;
    final portController = TextEditingController(text: '8080');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('访问本地服务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '访问 PC 上运行的本地开发服务（如 Vite、React dev server）。',
              style: TextStyle(fontSize: 13, color: AppTheme.neutral500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '端口号',
                hintText: '8080',
                border: OutlineInputBorder(),
                prefixText: '127.0.0.1:',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final port = int.tryParse(portController.text.trim());
              if (port == null || port < 1 || port > 65535) return;
              Navigator.pop(dialogContext);
              await ref.read(proxyStateProvider.notifier).start(
                    sessionId: session.id,
                    targetPort: port,
                  );
              if (mounted) {
                context.push(
                  '${AppRoutes.webview}?port=$port&title=${Uri.encodeComponent(session.title)}',
                );
              }
            },
            child: const Text('打开'),
          ),
        ],
      ),
    );
  }
}
