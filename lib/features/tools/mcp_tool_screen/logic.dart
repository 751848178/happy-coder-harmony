part of 'mcp_tool_screen.dart';

void _loadMcpSampleServers(_MCPToolScreenState state) {
  state._updateView(() {
    state._servers
      ..clear()
      ..addAll([
        MCPServerConfig(
          id: '1',
          name: 'Filesystem',
          command: 'npx',
          args: [
            '-y',
            '@modelcontextprotocol/server-filesystem',
            '/path/to/directory'
          ],
          type: MCPServerType.stdio,
          status: MCPServerStatus.connected,
          lastConnected: DateTime.now(),
          availableTools: [
            'read_file',
            'write_file',
            'list_directory',
            'create_directory'
          ],
        ),
        MCPServerConfig(
          id: '2',
          name: 'GitHub',
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-github'],
          type: MCPServerType.stdio,
          status: MCPServerStatus.disconnected,
          env: {'GITHUB_TOKEN': '***'},
          availableTools: [
            'create_pull_request',
            'create_issue',
            'list_issues'
          ],
        ),
        MCPServerConfig(
          id: '3',
          name: 'Brave Search',
          command: 'uvx',
          args: ['mcp-brave-search'],
          type: MCPServerType.stdio,
          status: MCPServerStatus.error,
          errorMessage: 'BRAVE_API_KEY not set',
          availableTools: ['search'],
        ),
      ]);
  });
}

void _toggleMcpServer(_MCPToolScreenState state, MCPServerConfig server) {
  _updateServerById(state, server.id, (_) {
    return server.copyWith(
      enabled: !server.enabled,
      status: !server.enabled
          ? MCPServerStatus.disconnected
          : MCPServerStatus.connecting,
    );
  });

  if (!server.enabled) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateServerById(state, server.id, (current) {
        return current.copyWith(
          status: MCPServerStatus.connected,
          lastConnected: DateTime.now(),
        );
      });
    });
  }
}

void _connectMcpServer(_MCPToolScreenState state, MCPServerConfig server) {
  _updateServerById(state, server.id, (_) {
    return server.copyWith(status: MCPServerStatus.connecting);
  });

  Future.delayed(const Duration(milliseconds: 1500), () {
    _updateServerById(state, server.id, (current) {
      return current.copyWith(
        status: MCPServerStatus.connected,
        lastConnected: DateTime.now(),
        errorMessage: null,
      );
    });
    state._showSnackBar('已连接到 ${server.name}', isError: false);
  });
}

void _disconnectMcpServer(_MCPToolScreenState state, MCPServerConfig server) {
  _updateServerById(state, server.id, (_) {
    return server.copyWith(
      status: MCPServerStatus.disconnected,
      lastConnected: null,
    );
  });
  state._showSnackBar('已断开 ${server.name}', isError: false);
}

void _deleteMcpServer(_MCPToolScreenState state, String id) {
  state._updateView(() {
    state._servers.removeWhere((server) => server.id == id);
  });
  state._showSnackBar('MCP 服务器已删除', isError: false);
}

void _showMcpSnackBar(
  _MCPToolScreenState state,
  String message, {
  required bool isError,
}) {
  ScaffoldMessenger.of(state.context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ),
  );
}

void _updateServerById(
  _MCPToolScreenState state,
  String serverId,
  MCPServerConfig Function(MCPServerConfig current) update,
) {
  state._updateView(() {
    final index = state._servers.indexWhere((server) => server.id == serverId);
    if (index == -1) {
      return;
    }
    state._servers[index] = update(state._servers[index]);
  });
}

String _mcpTypeLabel(MCPServerType type) {
  switch (type) {
    case MCPServerType.local:
      return '本地';
    case MCPServerType.remote:
      return '远程';
    case MCPServerType.stdio:
      return 'STDIO';
    case MCPServerType.sse:
      return 'SSE';
  }
}

String _formatMcpTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) {
    return '刚刚';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} 分钟前';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} 小时前';
  }
  return '${time.month}/${time.day} '
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
}

(Color, IconData, String) _mcpStatusPresentation(MCPServerStatus status) {
  switch (status) {
    case MCPServerStatus.connected:
      return (AppTheme.successColor, Icons.check_circle, '已连接');
    case MCPServerStatus.connecting:
      return (AppTheme.infoColor, Icons.sync, '连接中...');
    case MCPServerStatus.error:
      return (AppTheme.errorColor, Icons.error, '错误');
    case MCPServerStatus.disconnected:
      return (AppTheme.neutral400, Icons.power_off, '未连接');
  }
}
