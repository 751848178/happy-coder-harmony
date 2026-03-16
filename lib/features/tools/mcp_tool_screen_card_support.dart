part of 'mcp_tool_screen.dart';

Widget _buildMcpServerMenu(
  BuildContext context, {
  required MCPServerConfig server,
  required VoidCallback onConnect,
  required VoidCallback onDisconnect,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) {
      switch (value) {
        case 'connect':
          if (server.status != MCPServerStatus.connected) {
            onConnect();
          }
          return;
        case 'disconnect':
          if (server.status == MCPServerStatus.connected) {
            onDisconnect();
          }
          return;
        case 'edit':
          onEdit();
          return;
        case 'delete':
          _showMcpDeleteConfirmation(context,
              server: server, onDelete: onDelete);
          return;
      }
    },
    itemBuilder: (context) => [
      if (server.status != MCPServerStatus.connected)
        const PopupMenuItem(
          value: 'connect',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 12),
              Text('连接'),
            ],
          ),
        ),
      if (server.status == MCPServerStatus.connected)
        const PopupMenuItem(
          value: 'disconnect',
          child: Row(
            children: [
              Icon(Icons.stop, size: 18),
              SizedBox(width: 12),
              Text('断开'),
            ],
          ),
        ),
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 12),
            Text('编辑'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('删除', style: TextStyle(color: AppTheme.errorColor)),
          ],
        ),
      ),
    ],
  );
}

Widget _buildMcpInlineError(String errorMessage) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppTheme.errorColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            errorMessage,
            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMcpInlineTools(List<String> availableTools) {
  final visibleTools = availableTools.take(5).toList();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '可用工具',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral600,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...visibleTools.map(
            (tool) => Chip(
              label: Text(tool, style: const TextStyle(fontSize: 11)),
              backgroundColor: AppTheme.brandColor.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (availableTools.length > 5)
            Text(
              '+${availableTools.length - 5}',
              style: const TextStyle(fontSize: 11, color: AppTheme.neutral500),
            ),
        ],
      ),
    ],
  );
}

void _showMcpDeleteConfirmation(
  BuildContext context, {
  required MCPServerConfig server,
  required VoidCallback onDelete,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除 MCP 服务器'),
      content: Text('确认要删除 "${server.name}" 吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
