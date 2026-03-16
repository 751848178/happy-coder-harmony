part of 'mcp_tool_screen.dart';

class _MCPServerCard extends StatelessWidget {
  const _MCPServerCard({
    required this.server,
    required this.onTap,
    required this.onConnect,
    required this.onDisconnect,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final MCPServerConfig server;
  final VoidCallback onTap;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon, statusLabel) =
        _mcpStatusPresentation(server.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(statusColor, statusIcon, statusLabel, context),
              if (server.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildInlineError(),
              ],
              if (server.availableTools.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInlineTools(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color statusColor,
    IconData statusIcon,
    String statusLabel,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: server.enabled,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppTheme.brandColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.layers,
                      size: 14, color: AppTheme.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    '${server.availableTools.length} 工具',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.neutral500),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildMcpServerMenu(
          context,
          server: server,
          onConnect: onConnect,
          onDisconnect: onDisconnect,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }

  Widget _buildInlineError() => _buildMcpInlineError(server.errorMessage!);

  Widget _buildInlineTools() => _buildMcpInlineTools(server.availableTools);
}
