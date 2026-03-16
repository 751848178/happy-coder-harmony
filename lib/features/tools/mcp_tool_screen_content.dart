part of 'mcp_tool_screen.dart';

Widget _buildMcpToolScaffold(_MCPToolScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: _buildMcpAppBar(state),
    body: state._servers.isEmpty
        ? _buildMcpEmptyState()
        : _buildMcpServerList(state),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: state._showAddServerDialog,
      backgroundColor: AppTheme.brandColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('添加服务器'),
    ),
  );
}

PreferredSizeWidget _buildMcpAppBar(_MCPToolScreenState state) {
  return AppBar(
    backgroundColor: AppTheme.surface,
    foregroundColor: AppTheme.textPrimary,
    elevation: 0,
    title: const Text('MCP 扩展'),
    actions: [
      if (state._connectedCount > 0 || state._errorCount > 0)
        _buildMcpCountBadge(state),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          state._showSnackBar('正在刷新 MCP 服务器...', isError: false);
          Future.delayed(const Duration(milliseconds: 500), () {
            state._showSnackBar('刷新完成', isError: false);
          });
        },
        tooltip: '刷新',
      ),
    ],
  );
}

Widget _buildMcpCountBadge(_MCPToolScreenState state) {
  return Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.brandColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state._connectedCount > 0) ...[
          const Icon(Icons.cloud_done, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 4),
          Text(
            '${state._connectedCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (state._errorCount > 0 && state._connectedCount > 0)
          const SizedBox(width: 8),
        if (state._errorCount > 0) ...[
          const Icon(Icons.error_outline, size: 16, color: AppTheme.errorColor),
          const SizedBox(width: 4),
          Text(
            '${state._errorCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildMcpServerList(_MCPToolScreenState state) {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: state._servers.length,
    itemBuilder: (context, index) {
      final server = state._servers[index];
      return _MCPServerCard(
        server: server,
        onTap: () => state._showServerDetails(server),
        onConnect: () => state._connectServer(server),
        onDisconnect: () => state._disconnectServer(server),
        onEdit: () => state._showEditDialog(server),
        onDelete: () => state._deleteServer(server.id),
        onToggle: () => state._toggleServer(server),
      );
    },
  );
}

Widget _buildMcpEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.extension_off, size: 64, color: AppTheme.neutral400),
        const SizedBox(height: 16),
        const Text(
          '没有配置 MCP 服务器',
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 8),
        Text(
          '点击 + 按钮添加 MCP 扩展',
          style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
        ),
      ],
    ),
  );
}
