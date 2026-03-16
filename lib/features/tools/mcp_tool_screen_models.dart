part of 'mcp_tool_screen.dart';

/// MCP server status
enum MCPServerStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// MCP server type
enum MCPServerType {
  local,
  remote,
  stdio,
  sse,
}

/// MCP server configuration
class MCPServerConfig {
  MCPServerConfig({
    required this.id,
    required this.name,
    required this.command,
    this.args = const [],
    this.env = const {},
    required this.type,
    this.status = MCPServerStatus.disconnected,
    this.errorMessage,
    this.lastConnected,
    this.availableTools = const [],
    this.enabled = true,
  });

  final String id;
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final MCPServerType type;
  final MCPServerStatus status;
  final String? errorMessage;
  final DateTime? lastConnected;
  final List<String> availableTools;
  final bool enabled;

  MCPServerConfig copyWith({
    String? id,
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    MCPServerType? type,
    MCPServerStatus? status,
    String? errorMessage,
    DateTime? lastConnected,
    List<String>? availableTools,
    bool? enabled,
  }) {
    return MCPServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      type: type ?? this.type,
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastConnected: lastConnected ?? this.lastConnected,
      availableTools: availableTools ?? this.availableTools,
      enabled: enabled ?? this.enabled,
    );
  }
}
