import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSampleServers();
  }

  void _loadSampleServers() {
    setState(() {
      _servers.addAll([
        MCPServerConfig(
          id: '1',
          name: 'Filesystem',
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-filesystem', '/path/to/directory'],
          type: MCPServerType.stdio,
          status: MCPServerStatus.connected,
          lastConnected: DateTime.now(),
          availableTools: ['read_file', 'write_file', 'list_directory', 'create_directory'],
        ),
        MCPServerConfig(
          id: '2',
          name: 'GitHub',
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-github'],
          type: MCPServerType.stdio,
          status: MCPServerStatus.disconnected,
          env: {'GITHUB_TOKEN': '***'},
          availableTools: ['create_pull_request', 'create_issue', 'list_issues'],
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

  void _toggleServer(MCPServerConfig server) {
    setState(() {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server.copyWith(
          enabled: !server.enabled,
          status: !server.enabled
              ? MCPServerStatus.disconnected
              : MCPServerStatus.connecting,
        );

        // Simulate connection
        if (!server.enabled) {
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              final idx = _servers.indexWhere((s) => s.id == server.id);
              if (idx != -1) {
                _servers[idx] = _servers[idx].copyWith(
                  status: MCPServerStatus.connected,
                  lastConnected: DateTime.now(),
                );
              }
            });
          });
        }
      }
    });
  }

  void _connectServer(MCPServerConfig server) {
    setState(() {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server.copyWith(status: MCPServerStatus.connecting);
      }
    });

    // Simulate connection
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        final index = _servers.indexWhere((s) => s.id == server.id);
        if (index != -1) {
          _servers[index] = _servers[index].copyWith(
            status: MCPServerStatus.connected,
            lastConnected: DateTime.now(),
            errorMessage: null,
          );
        }
      });
      _showSnackBar('已连接到 ${server.name}', isError: false);
    });
  }

  void _disconnectServer(MCPServerConfig server) {
    setState(() {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        _servers[index] = server.copyWith(
          status: MCPServerStatus.disconnected,
          lastConnected: null,
        );
      }
    });
    _showSnackBar('已断开 ${server.name}', isError: false);
  }

  void _deleteServer(String id) {
    setState(() {
      _servers.removeWhere((s) => s.id == id);
    });
    _showSnackBar('MCP 服务器已删除', isError: false);
  }

  void _showAddServerDialog() {
    _showEditDialog();
  }

  void _showEditDialog([MCPServerConfig? server]) {
    final nameController = TextEditingController(text: server?.name ?? '');
    final commandController = TextEditingController(text: server?.command ?? '');
    final argsController = TextEditingController(text: server?.args.join(' ') ?? '');
    final envController = TextEditingController(text: server?.env.entries.map((e) => '${e.key}=${e.value}').join('\n') ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          MCPServerType selectedType = server?.type ?? MCPServerType.stdio;

          return AlertDialog(
            title: Text(server == null ? '添加 MCP 服务器' : '编辑 MCP 服务器'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '服务器类型',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<MCPServerType>(
                    segments: const [
                      ButtonSegment(
                        value: MCPServerType.local,
                        label: Text('本地'),
                      ),
                      ButtonSegment(
                        value: MCPServerType.stdio,
                        label: Text('STDIO'),
                      ),
                      ButtonSegment(
                        value: MCPServerType.sse,
                        label: Text('SSE'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<MCPServerType> newSelection) {
                      setDialogState(() => selectedType = newSelection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commandController,
                    decoration: const InputDecoration(
                      labelText: '命令',
                      border: OutlineInputBorder(),
                      hintText: '例如: npx, uvx',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: argsController,
                    decoration: const InputDecoration(
                      labelText: '参数',
                      border: OutlineInputBorder(),
                      hintText: '空格分隔的参数',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: envController,
                    decoration: const InputDecoration(
                      labelText: '环境变量（每行一个）',
                      border: OutlineInputBorder(),
                      hintText: 'KEY=value',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    _showSnackBar('请输入服务器名称', isError: true);
                    return;
                  }

                  final envMap = <String, String>{};
                  for (final line in envController.text.split('\n')) {
                    final parts = line.split('=');
                    if (parts.length == 2) {
                      envMap[parts[0].trim()] = parts[1].trim();
                    }
                  }

                  final newServer = MCPServerConfig(
                    id: server?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    command: commandController.text.trim(),
                    args: argsController.text.trim().split(' ').where((a) => a.isNotEmpty).toList(),
                    env: envMap,
                    type: selectedType,
                    status: MCPServerStatus.disconnected,
                  );

                  setState(() {
                    if (server != null) {
                      final index = _servers.indexWhere((s) => s.id == server.id);
                      if (index != -1) {
                        _servers[index] = _servers[index].copyWith(
                          name: newServer.name,
                          command: newServer.command,
                          args: newServer.args,
                          env: newServer.env,
                          type: newServer.type,
                        );
                      }
                    } else {
                      _servers.add(newServer);
                    }
                  });

                  Navigator.pop(context);
                  _showSnackBar('MCP 服务器已保存', isError: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showServerDetails(MCPServerConfig server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(server.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('状态', _buildStatusBadge(server.status)),
              _buildDetailRow('类型', _getTypeLabel(server.type)),
              _buildDetailRow('命令', server.command),
              _buildDetailRow('参数', server.args.join(' ') ?? '无'),
              if (server.env.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('环境变量:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...server.env.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${e.key} = ${e.key.contains('TOKEN') || e.key.contains('SECRET') || e.key.contains('KEY') ? '***' : e.value}'),
                    )),
              ],
              if (server.availableTools.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('可用工具:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: server.availableTools.map((tool) => Chip(
                    label: Text(tool),
                    backgroundColor: AppTheme.brandColor.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppTheme.brandColor,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
              ],
              if (server.lastConnected != null)
                _buildDetailRow('最后连接', _formatTime(server.lastConnected!)),
              if (server.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
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
                          server.errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildDetailRow(String label, dynamic value) {
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
                ? value as Widget
                : Text(
                    value?.toString() ?? '-',
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MCPServerStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case MCPServerStatus.connected:
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        label = '已连接';
        break;
      case MCPServerStatus.connecting:
        color = AppTheme.infoColor;
        icon = Icons.sync;
        label = '连接中...';
        break;
      case MCPServerStatus.error:
        color = AppTheme.errorColor;
        icon = Icons.error;
        label = '错误';
        break;
      case MCPServerStatus.disconnected:
      default:
        color = AppTheme.neutral400;
        icon = Icons.power_off;
        label = '未连接';
        break;
    }

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
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(MCPServerType type) {
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  int get _connectedCount => _servers.where((s) => s.status == MCPServerStatus.connected).length;
  int get _errorCount => _servers.where((s) => s.status == MCPServerStatus.error).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('MCP 扩展'),
        actions: [
          if (_connectedCount > 0 || _errorCount > 0)
            Container(
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
                  if (_connectedCount > 0) ...[
                    const Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_connectedCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_errorCount > 0 && _connectedCount > 0)
                    const SizedBox(width: 8),
                  if (_errorCount > 0) ...[
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_errorCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showSnackBar('正在刷新 MCP 服务器...', isError: false);
              // Simulate refresh
              Future.delayed(const Duration(milliseconds: 500), () {
                _showSnackBar('刷新完成', isError: false);
              });
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: _servers.isEmpty
          ? _buildEmptyState()
          : _buildServerList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServerDialog,
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('添加服务器'),
      ),
    );
  }

  Widget _buildServerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _servers.length,
      itemBuilder: (context, index) {
        final server = _servers[index];
        return _MCPServerCard(
          server: server,
          onTap: () => _showServerDetails(server),
          onConnect: () => _connectServer(server),
          onDisconnect: () => _disconnectServer(server),
          onEdit: () => _showEditDialog(server),
          onDelete: () => _deleteServer(server.id),
          onToggle: () => _toggleServer(server),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          const Text(
            '没有配置 MCP 服务器',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮添加 MCP 扩展',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }
}

/// MCP Server Card Widget
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

  Color get _statusColor {
    switch (server.status) {
      case MCPServerStatus.connected:
        return AppTheme.successColor;
      case MCPServerStatus.connecting:
        return AppTheme.infoColor;
      case MCPServerStatus.error:
        return AppTheme.errorColor;
      case MCPServerStatus.disconnected:
      default:
        return AppTheme.neutral400;
    }
  }

  IconData get _statusIcon {
    switch (server.status) {
      case MCPServerStatus.connected:
        return Icons.cloud_done;
      case MCPServerStatus.connecting:
        return Icons.sync;
      case MCPServerStatus.error:
        return Icons.error_outline;
      case MCPServerStatus.disconnected:
      default:
        return Icons.cloud_off;
    }
  }

  String get _statusLabel {
    switch (server.status) {
      case MCPServerStatus.connected:
        return '已连接';
      case MCPServerStatus.connecting:
        return '连接中...';
      case MCPServerStatus.error:
        return '错误';
      case MCPServerStatus.disconnected:
      default:
        return '未连接';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _statusIcon,
                      color: _statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Server info
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
                              activeColor: AppTheme.brandColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: _statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.layers,
                              size: 14,
                              color: AppTheme.neutral500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${server.availableTools.length} 工具',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'connect':
                          if (server.status != MCPServerStatus.connected) {
                            onConnect();
                          }
                          break;
                        case 'disconnect':
                          if (server.status == MCPServerStatus.connected) {
                            onDisconnect();
                          }
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (server.status != MCPServerStatus.connected)
                        PopupMenuItem(
                          value: 'connect',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 18),
                              const SizedBox(width: 12),
                              const Text('连接'),
                            ],
                          ),
                        ),
                      if (server.status == MCPServerStatus.connected)
                        PopupMenuItem(
                          value: 'disconnect',
                          child: Row(
                            children: [
                              Icon(Icons.stop, size: 18),
                              const SizedBox(width: 12),
                              const Text('断开'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            const SizedBox(width: 12),
                            const Text('编辑'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                            const SizedBox(width: 12),
                            Text('删除', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (server.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
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
                          server.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (server.availableTools.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                  children: server.availableTools.take(5).map((tool) => Chip(
                    label: Text(
                      tool,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppTheme.brandColor.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                if (server.availableTools.length > 5) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+${server.availableTools.length - 5}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
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
}
