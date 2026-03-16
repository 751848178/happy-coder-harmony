part of 'mcp_tool_screen.dart';

void _showMcpServerDetails(
  _MCPToolScreenState state,
  MCPServerConfig server,
) {
  showDialog<void>(
    context: state.context,
    builder: (context) => AlertDialog(
      title: Text(server.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMcpDetailRow('状态', _buildMcpStatusBadge(server.status)),
            _buildMcpDetailRow('类型', _mcpTypeLabel(server.type)),
            _buildMcpDetailRow('命令', server.command),
            _buildMcpDetailRow(
                '参数', server.args.isEmpty ? '无' : server.args.join(' ')),
            if (server.env.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('环境变量:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...server.env.entries.map(_buildEnvRow),
            ],
            if (server.availableTools.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('可用工具:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: server.availableTools.map(_buildToolChip).toList(),
              ),
            ],
            if (server.lastConnected != null)
              _buildMcpDetailRow('最后连接', _formatMcpTime(server.lastConnected!)),
            if (server.errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildMcpErrorBanner(server.errorMessage!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

Widget _buildMcpDetailRow(String label, Object value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral600,
            ),
          ),
        ),
        Expanded(
          child: value is Widget
              ? value
              : Text(
                  value.toString(),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
        ),
      ],
    ),
  );
}

Widget _buildMcpStatusBadge(MCPServerStatus status) {
  final (color, icon, label) = _mcpStatusPresentation(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _buildEnvRow(MapEntry<String, String> entry) {
  final hidden = entry.key.contains('TOKEN') ||
      entry.key.contains('SECRET') ||
      entry.key.contains('KEY');
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('${entry.key} = ${hidden ? '***' : entry.value}'),
  );
}

Widget _buildToolChip(String tool) {
  return Chip(
    label: Text(tool),
    backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
    labelStyle: const TextStyle(color: AppTheme.brandColor, fontSize: 12),
  );
}

Widget _buildMcpErrorBanner(String message) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.errorColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
