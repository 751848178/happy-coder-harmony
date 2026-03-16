import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'mcp_tool_screen_models.dart';
part 'mcp_tool_screen_logic.dart';
part 'mcp_tool_screen_content.dart';
part 'mcp_tool_screen_edit_dialog.dart';
part 'mcp_tool_screen_details_dialog.dart';
part 'mcp_tool_screen_card.dart';
part 'mcp_tool_screen_card_support.dart';

/// MCP Tool Screen
///
/// Provides an interface for managing MCP (Model Context Protocol) servers
class MCPToolScreen extends ConsumerStatefulWidget {
  const MCPToolScreen({super.key});

  @override
  ConsumerState<MCPToolScreen> createState() => _MCPToolScreenState();
}

class _MCPToolScreenState extends ConsumerState<MCPToolScreen> {
  final List<MCPServerConfig> _servers = [];

  int get _connectedCount => _servers
      .where((server) => server.status == MCPServerStatus.connected)
      .length;
  int get _errorCount =>
      _servers.where((server) => server.status == MCPServerStatus.error).length;

  void _updateView(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    _loadSampleServers();
  }

  void _loadSampleServers() => _loadMcpSampleServers(this);

  void _toggleServer(MCPServerConfig server) => _toggleMcpServer(this, server);

  void _connectServer(MCPServerConfig server) =>
      _connectMcpServer(this, server);

  void _disconnectServer(MCPServerConfig server) =>
      _disconnectMcpServer(this, server);

  void _deleteServer(String id) => _deleteMcpServer(this, id);

  void _showAddServerDialog() => _showMcpEditDialog(this);

  void _showEditDialog([MCPServerConfig? server]) =>
      _showMcpEditDialog(this, server);

  void _showServerDetails(MCPServerConfig server) =>
      _showMcpServerDetails(this, server);

  void _showSnackBar(String message, {required bool isError}) =>
      _showMcpSnackBar(this, message, isError: isError);

  @override
  Widget build(BuildContext context) => _buildMcpToolScaffold(this);
}
